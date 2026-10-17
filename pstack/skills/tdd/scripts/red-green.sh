#!/usr/bin/env bash
# Prove a test-first change from git history: the tests fail at the red commit,
# pass at HEAD, and nobody edited them in between.
#
# Usage: red-green.sh --red <commit> [--tests <path>]... -- <test command...>
#   --red    the commit that adds the failing tests, before any implementation.
#            Pass --red HEAD right after you commit the tests to confirm red.
#   --tests  a test file to hold frozen. Repeatable. Defaults to the files in
#            the red commit whose path looks like a test.
#   The working tree must be clean. The script checks out the red commit, runs
#   the command there, and always returns to the branch it started on.
#   Exit 0 when red and green both hold, 1 when they do not, 2 on misuse.
set -u

usage() { sed -n '2,/^set -u/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 2; }
die() { printf 'error: %s\n' "$1" >&2; exit 1; }

red=""
tests=()
while [ $# -gt 0 ]; do
	case "$1" in
	--red) [ $# -ge 2 ] || usage; red="$2"; shift 2 ;;
	--tests) [ $# -ge 2 ] || usage; tests+=("$2"); shift 2 ;;
	--) shift; break ;;
	*) usage ;;
	esac
done
[ -n "$red" ] && [ $# -gt 0 ] || usage

git rev-parse --git-dir >/dev/null 2>&1 || die "not inside a git repository"
cd "$(git rev-parse --show-toplevel)" || exit 1
red_sha="$(git rev-parse --verify -q "$red^{commit}")" || die "no such commit: $red"
head_sha="$(git rev-parse HEAD)"
git merge-base --is-ancestor "$red_sha" "$head_sha" || die "the red commit $red is not an ancestor of HEAD"
if ! git diff --quiet || ! git diff --cached --quiet; then
	die "the working tree has uncommitted changes. commit or stash them first"
fi

# Directory names match in any case (Tests/, __tests__/). File suffixes match
# FooTest.php, FooTests.cs, foo.test.ts, foo_test.go, and test_foo.py.
is_test() {
	printf '%s' "$1" | grep -Eiq '(^|/)(tests?|__tests__|specs?)/' ||
		printf '%s' "$1" | grep -Eq '([._-](test|tests|spec)|Tests?|Spec)\.[A-Za-z0-9]+$|(^|/)test_[^/]+$'
}

edited=()
derived=()
while IFS="$(printf '\t')" read -r status path; do
	[ -n "$path" ] && is_test "$path" || continue
	[ "$status" = M ] && edited+=("$path")
	derived+=("$path")
done < <(git diff-tree --root --no-commit-id --name-status -r "$red_sha")

if [ ${#tests[@]} -eq 0 ]; then
	tests=("${derived[@]+"${derived[@]}"}")
	[ ${#tests[@]} -gt 0 ] || die "the red commit has no file that looks like a test. Name them with --tests <path>"
fi

if [ ${#edited[@]} -gt 0 ]; then
	printf 'warning: the red commit edits existing test files: %s\n' "${edited[*]}" >&2
	printf 'warning: change an existing test only when its old assertion was wrong, never to fit new code. Say why in your report.\n' >&2
fi

if [ "$red_sha" != "$head_sha" ]; then
	changed="$(git diff --name-only "$red_sha" "$head_sha" -- "${tests[@]}")"
	[ -z "$changed" ] || die "these tests changed after the red commit: $(printf '%s' "$changed" | paste -sd ' ' -). Revert the edits, or make a new red commit and prove red again"
fi

start="$(git symbolic-ref -q --short HEAD || printf '%s' "$head_sha")"
logs="$(mktemp -d "${TMPDIR:-/tmp}/red-green.XXXXXX")"
trap 'git checkout -q "$start" 2>/dev/null' EXIT

run_at() {
	git -c advice.detachedHead=false checkout -q "$1" || die "cannot check out $1"
	"${@:3}" >"$2" 2>&1
}

tail_of() { tail -n 15 "$1" | sed 's/^/    /'; }

run_at "$red_sha" "$logs/red.log" "$@"
red_code=$?
if [ "$red_code" -eq 126 ] || [ "$red_code" -eq 127 ]; then
	tail_of "$logs/red.log" >&2
	die "the test command could not run at the red commit (exit $red_code). Fix the command, then rerun"
fi
if [ "$red_code" -eq 0 ]; then
	tail_of "$logs/red.log" >&2
	die "the tests pass before the implementation at ${red_sha:0:12}, so they do not prove the change. Write a test that fails first"
fi
printf 'RED   %s exit %s. The tests fail before the implementation. Log: %s\n' "${red_sha:0:12}" "$red_code" "$logs/red.log"
tail_of "$logs/red.log"

if [ "$red_sha" = "$head_sha" ]; then
	printf 'Red confirmed. Now implement until the command passes, without editing: %s\n' "${tests[*]}"
	exit 0
fi

run_at "$head_sha" "$logs/green.log" "$@"
green_code=$?
if [ "$green_code" -ne 0 ]; then
	tail_of "$logs/green.log" >&2
	die "the tests fail at HEAD ${head_sha:0:12} (exit $green_code). Fix the implementation, not the tests"
fi
printf 'GREEN %s exit 0. The same tests pass with the implementation. Log: %s\n' "${head_sha:0:12}" "$logs/green.log"
printf 'Frozen since red: %s\n' "${tests[*]}"
