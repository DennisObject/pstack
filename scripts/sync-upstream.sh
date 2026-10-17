#!/usr/bin/env bash
# Merge upstream pstack into this fork and rebuild the generated tree.
#
# Usage: scripts/sync-upstream.sh [--continue] [<remote> [<branch>]]
#   Fetches <remote>/<branch>, upstream/main by default, and merges it into the
#   current branch with a merge commit. The generated tree under harness/pstack
#   never needs a hand merge. The script rebuilds it with this fork's generator.
#   On a conflict outside the tree it stops and lists the files. Resolve them,
#   stage them, and run it again with --continue.
#   When the generator fails, the merge stays open. Fix the cause, stage it,
#   and run it again with --continue.
#   Finally it runs the generator check and every *.test.sh under scripts/ and
#   pstack/skills/*/scripts/, and says when to port an upstream adapter edit
#   or rerun the installer.
set -u

die() { printf 'error: %s\n' "$1" >&2; exit 1; }

cont=0
args=()
for arg in "$@"; do
	case "$arg" in
	--continue) cont=1 ;;
	-*) sed -n '2,/^set -u/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 2 ;;
	*) args+=("$arg") ;;
	esac
done
remote="${args[0]:-upstream}"
branch="${args[1]:-main}"

cd "$(git rev-parse --show-toplevel)" || exit 1
merging="$(git rev-parse --git-dir)/MERGE_HEAD"

generate() { node scripts/generate-pstack-harness-trees.mjs "$@" >/dev/null; }

source_conflicts() { git diff --name-only --diff-filter=U | grep -v '^harness/pstack/' || true; }

finish_merge() {
	generate || die "the generator failed. Fix the cause, stage the fix, then run $0 --continue"
	git add -A harness/pstack
	git commit -q --no-edit || die "the merge commit failed"
}

notices() {
	local adapter skills
	adapter="$(git diff --name-only HEAD^1 HEAD -- pstack/docs/harness)"
	skills="$(git diff --name-status HEAD^1 HEAD -- 'pstack/skills/*/SKILL.md' | grep -E '^[AD]' || true)"
	if [ -n "$adapter" ]; then
		printf 'note: upstream changed %s. Port what applies into pstack/skills/pstack-harness/references/claude-code.md.\n' "$(printf '%s' "$adapter" | paste -sd ' ' -)"
	fi
	if [ -n "$skills" ]; then
		printf 'note: skills were added or removed. Rerun scripts/install-portable-pstack.sh.\n'
	fi
}

if [ "$cont" -eq 1 ]; then
	[ -f "$merging" ] || die "no merge in progress"
	left="$(source_conflicts)"
	[ -z "$left" ] || die "still unresolved: $(printf '%s' "$left" | paste -sd ' ' -)"
	finish_merge
	notices
else
	[ ! -f "$merging" ] || die "a merge is in progress. Resolve it, then run with --continue"
	if ! git diff --quiet || ! git diff --cached --quiet; then
		die "the working tree has uncommitted changes. commit or stash them first"
	fi
	git fetch -q "$remote" "$branch" || die "cannot fetch $branch from $remote"
	if ! git merge -q --no-ff --no-commit "$remote/$branch" >/dev/null 2>&1; then
		left="$(source_conflicts)"
		if [ -n "$left" ]; then
			printf 'error: resolve these conflicts, stage them, then run %s --continue:\n%s\n' "$0" "$left" >&2
			exit 1
		fi
	fi
	if [ -f "$merging" ]; then
		finish_merge
		notices
	fi
fi

generate --check || die "the generated tree is still out of date"
status=0
for test in scripts/*.test.sh pstack/skills/*/scripts/*.test.sh; do
	[ -f "$test" ] || continue
	printf '%s: ' "$test"
	bash "$test" | tail -1
	[ "${PIPESTATUS[0]}" -eq 0 ] || status=1
done
[ "$status" -eq 0 ] || die "a test failed after the merge"
printf 'merged %s/%s at %s\n' "$remote" "$branch" "$(git rev-parse --short HEAD)"
