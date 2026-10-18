#!/usr/bin/env bash
# Tests for install-portable-pstack.sh against a throwaway HOME.
# Run: bash scripts/install-portable-pstack.test.sh
set -u

repo="$(cd "$(dirname "$0")/.." && pwd)"
script="$repo/scripts/install-portable-pstack.sh"
failures=0
n=0
homes=()
trap 'rm -rf "${homes[@]}"' EXIT

fresh_home() {
	HOME="$(mktemp -d)"
	homes+=("$HOME")
	export HOME
	unset CLAUDE_CONFIG_DIR GROK_HOME XDG_CONFIG_HOME
	mkdir -p "$HOME/.claude/skills/my-own-skill"
	printf '# My rules\n\nKeep this line.\n' > "$HOME/.claude/CLAUDE.md"
	printf '{\n  "theme": "dark",\n  "permissions": { "allow": ["Bash(ls:*)"] }\n}\n' > "$HOME/.claude/settings.json"
}

ok() {
	n=$((n + 1))
	if ! eval "$2"; then
		failures=$((failures + 1))
		printf 'FAIL %s\n' "$1"
	fi
}

install() { bash "$script" "$@" >"$HOME/out.log" 2>&1; rc=$?; }

fresh_home
install
ok "install exits 0" '[ $rc -eq 0 ] || { cat "$HOME/out.log"; false; }'
ok "links poteto-mode for Claude Code and Grok" '[ -L "$HOME/.claude/skills/poteto-mode" ] && [ -f "$HOME/.claude/skills/poteto-mode/SKILL.md" ]'
ok "links the harness skill" '[ -f "$HOME/.claude/skills/pstack-harness/SKILL.md" ]'
ok "links the cursor-team-kit companions" '[ -f "$HOME/.claude/skills/deslop/SKILL.md" ] && [ -f "$HOME/.claude/skills/control-ui/SKILL.md" ]'
ok "links from the generated tree" 'grep -q "pstack harness skill" "$HOME/.claude/skills/tdd/SKILL.md"'
ok "links the companions from the generated tree" 'readlink "$HOME/.claude/skills/deslop" | grep -q "harness/pstack/claude-code/skills/deslop"'
ok "a skill reaches the harness skill through its relative link" '[ -f "$HOME/.claude/skills/tdd/../pstack-harness/SKILL.md" ]'
ok "leaves unrelated skills alone" '[ -d "$HOME/.claude/skills/my-own-skill" ]'
ok "links agents for Claude Code" '[ -L "$HOME/.claude/agents/poteto-agent.md" ] && [ -L "$HOME/.claude/agents/comment-sicko.md" ]'
ok "links agents for Grok" '[ -L "$HOME/.grok/agents/poteto-agent.md" ]'
ok "writes the default model config" 'grep -q "^judgment and prose: claude-opus-5-5-xhigh" "$HOME/.config/pstack/models.md"'
ok "writes the speed setting into the default model config" 'grep -qx "# speed: fast" "$HOME/.config/pstack/models.md"'
ok "reviews with two Claude seats by default" 'grep -qx "interrogate reviewers: claude-opus-5-5-xhigh, claude-sonnet-5-5-xhigh" "$HOME/.config/pstack/models.md"'
ok "writes everyday code with Sonnet by default" 'grep -qx "feature, refactoring: claude-sonnet-5-5-xhigh" "$HOME/.config/pstack/models.md" && grep -qx "bug-fix: claude-sonnet-5-5-xhigh" "$HOME/.config/pstack/models.md"'
ok "keeps Grok on parallel and bulk work by default" 'grep -qx "swarm workers: grok-4.7-xhigh-fast" "$HOME/.config/pstack/models.md" && grep -qx "hillclimb: grok-4.7-xhigh-fast" "$HOME/.config/pstack/models.md"'
ok "adds the rules block to CLAUDE.md and keeps the user text" 'grep -q "Keep this line." "$HOME/.claude/CLAUDE.md" && grep -q "pstack-portable:begin" "$HOME/.claude/CLAUDE.md"'
ok "adds the rules block for Grok" 'grep -q "AI attribution" "$HOME/.grok/AGENTS.md"'
ok "the rules block names the skill files by path" 'grep -q "$HOME/.claude/skills/git-conventions/SKILL.md" "$HOME/.claude/CLAUDE.md"'
ok "the rules block lets project rules win" 'grep -qi "project" "$HOME/.grok/AGENTS.md"'
ok "turns off Claude Code attribution and keeps other settings" 'node -e "const s=require(process.argv[1]); if (s.attribution.commit !== \"\" || s.attribution.pr !== \"\" || s.theme !== \"dark\" || s.permissions.allow[0] !== \"Bash(ls:*)\") process.exit(1)" "$HOME/.claude/settings.json"'

printf 'judgment and prose: claude-sonnet-5-5-high\n' > "$HOME/.config/pstack/models.md"
install
ok "a second run exits 0" '[ $rc -eq 0 ]'
ok "a second run keeps one rules block" '[ "$(grep -c "pstack-portable:begin" "$HOME/.claude/CLAUDE.md")" -eq 1 ]'
ok "a second run keeps the user model config" 'grep -qx "judgment and prose: claude-sonnet-5-5-high" "$HOME/.config/pstack/models.md"'

install --uninstall
ok "uninstall exits 0" '[ $rc -eq 0 ]'
ok "uninstall removes the links" '[ ! -e "$HOME/.claude/skills/poteto-mode" ] && [ ! -e "$HOME/.grok/agents/poteto-agent.md" ]'
ok "uninstall keeps unrelated skills" '[ -d "$HOME/.claude/skills/my-own-skill" ]'
ok "uninstall removes the rules block and keeps the user text" '! grep -q "pstack-portable" "$HOME/.claude/CLAUDE.md" && grep -q "Keep this line." "$HOME/.claude/CLAUDE.md"'

fresh_home
before="$(cd "$HOME" && find . | sort | md5sum)"
install --dry-run
ok "dry run exits 0" '[ $rc -eq 0 ]'
rm "$HOME/out.log"
ok "dry run changes nothing" '[ "$(cd "$HOME" && find . | sort | md5sum)" = "$before" ]'

fresh_home
mkdir -p "$HOME/.claude/skills/how"
printf 'mine\n' > "$HOME/.claude/skills/how/SKILL.md"
install
ok "a same-named skill the user owns fails the install" '[ $rc -eq 1 ] && grep -q "how" "$HOME/out.log" && grep -qi "shadow" "$HOME/out.log"'
ok "keeps the same-named skill the user owns" '[ ! -L "$HOME/.claude/skills/how" ] && grep -q mine "$HOME/.claude/skills/how/SKILL.md"'
ok "installs the rest around the collision" '[ -L "$HOME/.claude/skills/poteto-mode" ]'

fresh_home
mkdir -p "$HOME/dotfiles"
mv "$HOME/.claude/settings.json" "$HOME/dotfiles/settings.json"
ln -s "$HOME/dotfiles/settings.json" "$HOME/.claude/settings.json"
install
ok "writes a symlinked settings file through the link" '[ -L "$HOME/.claude/settings.json" ] && grep -q attribution "$HOME/dotfiles/settings.json"'

fresh_home
printf '{ "theme": "dark", }\n' > "$HOME/.claude/settings.json"
install
ok "invalid settings JSON fails the install" '[ $rc -ne 0 ] && grep -qi "settings" "$HOME/out.log"'

fresh_home
ln -s "$repo/harness/pstack/claude-code/skills/retired-skill" "$HOME/.claude/skills/retired-skill"
install
ok "removes a stale link into this checkout" '[ ! -L "$HOME/.claude/skills/retired-skill" ]'

fresh_home
export CLAUDE_CONFIG_DIR="$HOME/custom-claude"
install
ok "honors CLAUDE_CONFIG_DIR" '[ -L "$HOME/custom-claude/skills/poteto-mode" ]'
unset CLAUDE_CONFIG_DIR

if [ "$failures" -eq 0 ]; then
	printf 'ok %s tests\n' "$n"
else
	printf '%s of %s tests failed\n' "$failures" "$n"
	exit 1
fi
