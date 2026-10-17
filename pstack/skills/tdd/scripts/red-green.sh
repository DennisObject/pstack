#!/usr/bin/env bash
# Prove a test-first change from git history: the tests fail at the red commit,
# pass at HEAD, and no test or test config changed in between.
#
# Usage: red-green.sh --red <commit> [--expect <regex>] [--tests <path>]...
#                     [--freeze <path>]... -- <test command...>
#   Run it from the project's repository, in the directory where the test
#   command works. The command runs in that directory at both commits.
#   --red     the commit that adds the failing tests, before any implementation.
#             Pass --red HEAD right after you commit the tests to confirm red.
#   --expect  a pattern the red run's output must match, such as the new test's
#             name, so a red caused by something else does not count.
#   --tests   a test file that must be in the red commit. Repeatable.
#   --freeze  any other file that must not change after the red commit.
#             Repeatable.
#   Frozen from the red commit on: every file the red commit adds or changes,
#   and every file in the repository that looks like a test or a test config.
#   So put a not-implemented stub in its own commit before the red commit.
#   The tree must be clean, untracked files included. The script checks out the
#   red commit, runs the command, and returns to the branch it started on.
#   Exit 0 when red and green both hold, 1 when they do not, 2 on misuse.
set -u

usage() { sed -n '2,/^set -u/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 2; }
die() { printf 'error: %s\n' "$1" >&2; exit 1; }

red=""
expect=""
tests=()
freeze=()
while [ $# -gt 0 ]; do
	case "$1" in
	--red) [ $# -ge 2 ] || usage; red="$2"; shift 2 ;;
	--expect) [ $# -ge 2 ] || usage; expect="$2"; shift 2 ;;
	--tests) [ $# -ge 2 ] || usage; tests+=("$2"); shift 2 ;;
	--freeze) [ $# -ge 2 ] || usage; freeze+=("$2"); shift 2 ;;
	--) shift; break ;;
	*) usage ;;
	esac
done
[ -n "$red" ] && [ $# -gt 0 ] || usage

git rev-parse --git-dir >/dev/null 2>&1 || die "not inside a git repository. Run this from the project's repository"
prefix="$(git rev-parse --show-prefix)"
cd "$(git rev-parse --show-toplevel)" || exit 1
red_sha="$(git rev-parse --verify -q "$red^{commit}")" || die "no such commit: $red"
head_sha="$(git rev-parse HEAD)"
git merge-base --is-ancestor "$red_sha" "$head_sha" || die "the red commit $red is not an ancestor of HEAD"
[ -z "$(git status --porcelain)" ] || die "the working tree has uncommitted or untracked files. commit or stash them first"

# Directories match in any case (tests/, __tests__/, App.Tests/, UnitTests/).
# Files match FooTest.php, FooTests.cs, foo.test.ts, foo_test.go, and test_foo.py.
is_test() {
	printf '%s' "$1" | grep -Eiq '(^|/)(tests?|__tests__|specs?)/|(^|/)[^/]*[._-](tests?|specs?)/' ||
		printf '%s' "$1" | grep -Eq '(^|/)[A-Za-z0-9]*(Tests?|Specs?)/|([._-](test|tests|spec)|Tests?|Spec)\.[A-Za-z0-9]+$|(^|/)test_[^/]+$'
}
is_test_config() {
	printf '%s' "$1" | grep -Eq '(^|/)(phpunit\.xml(\.dist)?|phpunit\.dist\.xml|pest\.php|(jest|vitest|playwright|cypress)\.config\.[a-z]+|karma\.conf\.[a-z]+|\.mocharc\.[a-z]+|pytest\.ini|conftest\.py|tox\.ini|xunit\.runner\.json|[^/]*\.runsettings)$'
}
in_list() {
	local item="$1" entry
	shift
	for entry in "$@"; do [ "$entry" = "$item" ] && return 0; done
	return 1
}

for path in "${tests[@]+"${tests[@]}"}"; do
	git cat-file -e "$red_sha:$path" 2>/dev/null || die "--tests $path is not in the red commit. Check the path"
done

proven=("${tests[@]+"${tests[@]}"}")
edited=()
while IFS="$(printf '\t')" read -r status path; do
	case "$status" in A | M) ;; *) continue ;; esac
	[ "$status" = M ] && is_test "$path" && edited+=("$path")
	in_list "$path" "${proven[@]+"${proven[@]}"}" || proven+=("$path")
done < <(git diff-tree --root --no-commit-id --name-status -r "$red_sha")
[ ${#proven[@]} -gt 0 ] || die "the red commit adds or changes no file"

if [ ${#edited[@]} -gt 0 ]; then
	printf 'warning: the red commit edits existing test files: %s\n' "${edited[*]}" >&2
	printf 'warning: change an existing test only when its old assertion was wrong, never to fit new code. Say why in your report.\n' >&2
fi

# Compare contents, so a mode change such as chmod +x is not an edit.
changed=()
stubs=()
while IFS= read -r path; do
	[ -n "$path" ] || continue
	is_test "$path" || is_test_config "$path" || in_list "$path" "${proven[@]}" ||
		in_list "$path" "${freeze[@]+"${freeze[@]}"}" || continue
	[ "$(git rev-parse -q --verify "$red_sha:$path")" = "$(git rev-parse -q --verify "$head_sha:$path")" ] && continue
	changed+=("$path")
	is_test "$path" || is_test_config "$path" || stubs+=("$path")
done < <(git diff --name-only "$red_sha" "$head_sha")
if [ ${#stubs[@]} -gt 0 ]; then
	die "files from the red commit changed after it: ${stubs[*]}. A fixture must stay as the red commit left it. A not-implemented stub belongs in an earlier commit, before the red commit"
fi
[ ${#changed[@]} -eq 0 ] || die "these tests or test configs changed after the red commit: ${changed[*]}. Revert the edits, or fold a corrected test into the red commit and prove red again"

start="$(git symbolic-ref -q --short HEAD || printf '%s' "$head_sha")"
logs="$(mktemp -d "${TMPDIR:-/tmp}/red-green.XXXXXX")"
trap 'git checkout -q "$start" 2>/dev/null || printf "error: could not return to %s. Run: git checkout -f %s\n" "$start" "$start" >&2' EXIT

# run_at <commit> <log> <command...>: runs the command in the caller's directory
# and fails the check when the command rewrote a tracked file.
run_at() {
	git -c advice.detachedHead=false checkout -q "$1" || die "cannot check out $1"
	(cd "./$prefix" && "${@:3}") >"$2" 2>&1
	local code=$?
	local rewritten
	rewritten="$(git diff --name-only)"
	if [ -n "$rewritten" ]; then
		git reset -q --hard
		die "the test command changed tracked files: $(printf '%s' "$rewritten" | paste -sd ' ' -). Tests must not rewrite what they check"
	fi
	return "$code"
}

tail_of() { tail -n 15 "$1" | sed 's/^/    /'; }

run_at "$red_sha" "$logs/red.log" "$@"
red_code=$?
if [ "$red_code" -eq 126 ] || [ "$red_code" -eq 127 ]; then
	tail_of "$logs/red.log" >&2
	die "the test command could not run at the red commit (exit $red_code). Run this from the directory where the command works"
fi
if [ "$red_code" -eq 0 ]; then
	tail_of "$logs/red.log" >&2
	die "the tests pass before the implementation at ${red_sha:0:12}, so they do not prove the change. Write a test that fails first"
fi
if [ -n "$expect" ] && ! grep -Eq -- "$expect" "$logs/red.log"; then
	tail_of "$logs/red.log" >&2
	die "the red run failed, but its output does not match the expected failure '$expect'. Make sure it fails for the missing behavior"
fi
printf 'RED   %s exit %s. The tests fail before the implementation. Log: %s\n' "${red_sha:0:12}" "$red_code" "$logs/red.log"
tail_of "$logs/red.log"

if [ "$red_sha" = "$head_sha" ]; then
	printf 'Red confirmed. Now implement until the command passes, without editing: %s\n' "${proven[*]}"
	exit 0
fi

run_at "$head_sha" "$logs/green.log" "$@"
green_code=$?
if [ "$green_code" -ne 0 ]; then
	tail_of "$logs/green.log" >&2
	die "the tests fail at HEAD ${head_sha:0:12} (exit $green_code). Fix the implementation, not the tests"
fi
printf 'GREEN %s exit 0. The same tests pass with the implementation. Log: %s\n' "${head_sha:0:12}" "$logs/green.log"
printf 'Proven by: %s. Every test and test config is unchanged since red.\n' "${proven[*]}"
