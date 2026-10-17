#!/usr/bin/env bash
# Merge upstream pstack into this fork and rebuild the generated tree.
#
# Usage: scripts/sync-upstream.sh [--continue] [<remote> [<branch>]]
#   Fetches <remote>/<branch>, upstream/main by default, and merges it into the
#   current branch with a merge commit. The generated tree under harness/pstack
#   never needs a hand merge. The script rebuilds it with this fork's generator.
#   On a conflict outside the tree it stops and lists the files. Resolve them,
#   stage them, and run it again with --continue.
#   Finally it runs the generator check and every *.test.sh under scripts/ and
#   pstack/skills/*/scripts/.
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

rebuild_tree() {
	rm -rf harness/pstack
	generate || die "the generator failed. Fix it, then run with --continue"
	git add -A harness/pstack
}

if [ "$cont" -eq 1 ]; then
	[ -f "$merging" ] || die "no merge in progress"
	left="$(source_conflicts)"
	[ -z "$left" ] || die "still unresolved: $(printf '%s' "$left" | paste -sd ' ' -)"
	rebuild_tree
	git commit -q --no-edit || die "the merge commit failed"
else
	[ ! -f "$merging" ] || die "a merge is in progress. Resolve it, then run with --continue"
	if ! git diff --quiet || ! git diff --cached --quiet; then
		die "the working tree has uncommitted changes. commit or stash them first"
	fi
	git fetch -q "$remote" "$branch" || die "cannot fetch $branch from $remote"
	before="$(git rev-parse HEAD)"
	if git merge -q --no-ff --no-edit "$remote/$branch" >/dev/null 2>&1; then
		if [ "$(git rev-parse HEAD)" != "$before" ] && ! generate --check; then
			rebuild_tree
			git commit -q --amend --no-edit
		fi
	else
		left="$(source_conflicts)"
		if [ -n "$left" ]; then
			printf 'error: resolve these conflicts, stage them, then run %s --continue:\n%s\n' "$0" "$left" >&2
			exit 1
		fi
		rebuild_tree
		git commit -q --no-edit || die "the merge commit failed"
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
