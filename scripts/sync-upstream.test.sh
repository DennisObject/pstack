#!/usr/bin/env bash
# Tests for sync-upstream.sh with a synthetic upstream and fork. A stub
# generator copies each skill into the tree with a marker line, so upstream and
# the fork generate different trees, as the real generators do.
# Run: bash scripts/sync-upstream.test.sh
set -u

script="$(cd "$(dirname "$0")" && pwd)/sync-upstream.sh"
root="$(mktemp -d)"
trap 'rm -rf "$root"' EXIT
failures=0
n=0

ok() {
	n=$((n + 1))
	if ! eval "$2"; then
		failures=$((failures + 1))
		printf 'FAIL %s\n' "$1"
		[ -f "$root/out.log" ] && sed 's/^/    /' "$root/out.log"
	fi
}

git_init() {
	git init -q -b main "$1"
	git -C "$1" config user.email t@example.com
	git -C "$1" config user.name t
	git -C "$1" config commit.gpgsign false
}

generate() { (cd "$1" && node scripts/generate-pstack-harness-trees.mjs); }

setup() {
	rm -rf "$root/up" "$root/fork"
	git_init "$root/up"
	mkdir -p "$root/up/pstack/skills/alpha" "$root/up/scripts"
	printf '# Alpha\n\nLine one.\n' > "$root/up/pstack/skills/alpha/SKILL.md"
	printf 'upstream\n' > "$root/up/marker"
	cat > "$root/up/scripts/generate-pstack-harness-trees.mjs" <<'EOF'
import { cpSync, existsSync, mkdtempSync, readdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { execSync } from "node:child_process";
import { join } from "node:path";
const marker = readFileSync("marker", "utf8").trim();
const build = (out) => {
	rmSync(out, { recursive: true, force: true });
	for (const skill of readdirSync("pstack/skills")) {
		cpSync(join("pstack/skills", skill), join(out, skill), { recursive: true });
		const file = join(out, skill, "SKILL.md");
		writeFileSync(file, readFileSync(file, "utf8") + `GEN ${marker}\n`);
	}
};
if (process.argv.includes("--check")) {
	const tmp = mkdtempSync("/tmp/gen-");
	build(tmp);
	const same = existsSync("harness/pstack") && execSync(`diff -r ${tmp} harness/pstack >/dev/null && echo same || echo diff`).toString().trim() === "same";
	rmSync(tmp, { recursive: true, force: true });
	if (!same) { console.log("harness/pstack is out of date."); process.exit(1); }
} else build("harness/pstack");
EOF
	generate "$root/up"
	git -C "$root/up" add -A && git -C "$root/up" commit -qm "feat: start"

	git clone -q "$root/up" "$root/fork"
	git -C "$root/fork" config user.email t@example.com
	git -C "$root/fork" config user.name t
	git -C "$root/fork" config commit.gpgsign false
	git -C "$root/fork" remote rename origin upstream
	git -C "$root/fork" switch -q -c portable
	printf 'fork\n' > "$root/fork/marker"
	generate "$root/fork"
	git -C "$root/fork" add -A && git -C "$root/fork" commit -qm "feat: fork marker"
}

sync() { (cd "$root/fork" && bash "$script" "$@") >"$root/out.log" 2>&1; rc=$?; }

setup
mkdir -p "$root/up/pstack/skills/beta"
printf '# Beta\n' > "$root/up/pstack/skills/beta/SKILL.md"
generate "$root/up"
git -C "$root/up" add -A && git -C "$root/up" commit -qm "feat: add beta"
sync
ok "a clean merge exits 0" '[ $rc -eq 0 ]'
ok "brings in the upstream skill" '[ -f "$root/fork/pstack/skills/beta/SKILL.md" ]'
ok "regenerates the tree with the fork generator" 'grep -q "GEN fork" "$root/fork/harness/pstack/beta/SKILL.md"'
ok "leaves the tree up to date" '(cd "$root/fork" && node scripts/generate-pstack-harness-trees.mjs --check >/dev/null)'
ok "leaves a clean working tree" '[ -z "$(git -C "$root/fork" status --porcelain)" ]'
ok "records one merge commit" '[ "$(git -C "$root/fork" rev-list --merges --count HEAD)" -eq 1 ]'

sync
ok "a sync with nothing new exits 0" '[ $rc -eq 0 ]'
ok "a sync with nothing new adds no commit" '[ "$(git -C "$root/fork" rev-list --merges --count HEAD)" -eq 1 ]'

setup
printf '# Alpha\n\nLine one, from upstream.\n' > "$root/up/pstack/skills/alpha/SKILL.md"
generate "$root/up"
git -C "$root/up" add -A && git -C "$root/up" commit -qm "docs: reword alpha"
printf '# Alpha\n\nLine one, from the fork.\n' > "$root/fork/pstack/skills/alpha/SKILL.md"
generate "$root/fork"
git -C "$root/fork" add -A && git -C "$root/fork" commit -qm "docs: reword alpha in the fork"
sync
ok "a source conflict exits 1" '[ $rc -eq 1 ]'
ok "a source conflict names the file" 'grep -q "pstack/skills/alpha/SKILL.md" "$root/out.log"'
ok "a source conflict does not list the generated tree" '! grep -q "harness/pstack/alpha" "$root/out.log"'
ok "a source conflict leaves the merge for the user" '[ -f "$root/fork/.git/MERGE_HEAD" ]'

printf '# Alpha\n\nLine one, from both.\n' > "$root/fork/pstack/skills/alpha/SKILL.md"
git -C "$root/fork" add pstack/skills/alpha/SKILL.md
sync --continue
ok "--continue finishes the merge" '[ $rc -eq 0 ] && [ ! -f "$root/fork/.git/MERGE_HEAD" ] && [ "$(git -C "$root/fork" rev-list --merges --count HEAD)" -eq 1 ]'
ok "--continue regenerates the conflicted tree" 'grep -q "from both" "$root/fork/harness/pstack/alpha/SKILL.md" && grep -q "GEN fork" "$root/fork/harness/pstack/alpha/SKILL.md"'
ok "--continue leaves a clean tree" '[ -z "$(git -C "$root/fork" status --porcelain)" ]'

setup
printf 'stray\n' >> "$root/fork/marker"
sync
ok "a dirty tree is refused" '[ $rc -eq 1 ] && grep -q "commit or stash" "$root/out.log"'

if [ "$failures" -eq 0 ]; then
	printf 'ok %s tests\n' "$n"
else
	printf '%s of %s tests failed\n' "$failures" "$n"
	exit 1
fi
