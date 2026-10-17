#!/usr/bin/env bash
# Install pstack for Claude Code and Grok from this checkout. Safe to rerun.
#
# Usage: scripts/install-portable-pstack.sh [--dry-run] [--uninstall]
#   Links each skill of the generated tree, which includes deslop, control-ui,
#   and control-cli from cursor-team-kit, into ~/.claude/skills/. Grok reads
#   that folder too. Links the pstack agents into ~/.claude/agents/ and ~/.grok/agents/.
#   Writes ~/.config/pstack/models.md with the default role models when it is
#   missing. Adds a short rules block (no AI attribution, Conventional Commits,
#   no frontend tests) to ~/.claude/CLAUDE.md and ~/.grok/AGENTS.md, and sets
#   Claude Code's commit and PR attribution to empty.
#   Never replaces a skill or agent you own. A same-named skill of yours would
#   shadow pstack's, so the install reports it and exits 1. Links follow
#   `git pull`, so rerun only when a skill is added or removed. A rerun also
#   removes links to skills that no longer exist.
#   Honors CLAUDE_CONFIG_DIR, GROK_HOME, and XDG_CONFIG_HOME.
#   --uninstall removes the links and the rules block. It keeps models.md and
#   the attribution setting.
set -u

dry=0
uninstall=0
for arg in "$@"; do
	case "$arg" in
	--dry-run) dry=1 ;;
	--uninstall) uninstall=1 ;;
	*) sed -n '2,/^set -u/p' "$0" | sed '$d; s/^# \{0,1\}//' >&2; exit 2 ;;
	esac
done

repo="$(cd "$(dirname "$0")/.." && pwd)"
tree="$repo/harness/pstack/claude-code"
claude="${CLAUDE_CONFIG_DIR:-$HOME/.claude}"
grok="${GROK_HOME:-$HOME/.grok}"
config="${XDG_CONFIG_HOME:-$HOME/.config}/pstack"
begin='<!-- pstack-portable:begin -->'
end='<!-- pstack-portable:end -->'

say() { printf '%s\n' "$1"; }
act() {
	say "$1"
	[ "$dry" -eq 1 ] || "${@:2}"
}

[ -d "$tree/skills" ] || { say "error: no generated tree at $tree. Run node scripts/generate-pstack-harness-trees.mjs" >&2; exit 1; }
if command -v node >/dev/null 2>&1; then
	node "$repo/scripts/generate-pstack-harness-trees.mjs" --check >/dev/null ||
		{ say "error: the generated tree is out of date. Run node scripts/generate-pstack-harness-trees.mjs" >&2; exit 1; }
fi

shadowed=()

# link <source> <target>: replaces a link into this checkout or a dangling one.
# Anything else at the target belongs to the user and stays.
link() {
	if [ -L "$2" ]; then
		[ "$(readlink "$2")" = "$1" ] && return
		case "$(readlink "$2")" in
		"$repo"/*) ;;
		*) [ -e "$2" ] && { shadowed+=("$2"); return; } ;;
		esac
	elif [ -e "$2" ]; then
		shadowed+=("$2")
		return
	fi
	act "link $2" mkdir -p "$(dirname "$2")"
	[ "$dry" -eq 1 ] || ln -sfn "$1" "$2"
}

unlink_ours() {
	local target
	for target in "$@"; do
		[ -L "$target" ] || continue
		case "$(readlink "$target")" in
		"$repo"/*) act "remove $target" rm "$target" ;;
		esac
	done
}

remove_stale() {
	local target
	for target in "$claude"/skills/* "$claude"/agents/* "$grok"/agents/*; do
		[ -L "$target" ] && [ ! -e "$target" ] || continue
		case "$(readlink "$target")" in
		"$repo"/*) act "remove stale $target" rm "$target" ;;
		esac
	done
}

# rules_block <file>: writes the block between the markers, or removes it on uninstall.
rules_block() {
	local file="$1" body=""
	[ "$uninstall" -eq 1 ] && [ ! -f "$file" ] && return
	if [ "$uninstall" -eq 0 ]; then
		body="$begin
## Git and tests (pstack)

A repository's own AGENTS.md, CLAUDE.md, PR template, or commitlint config wins over these rules, except the first one. Say which file won.

- Never add AI attribution to commits, PR titles, PR bodies, or review replies. No Co-Authored-By or similar trailer that names a model, a tool, or a bot, no \"Generated with\" line, and no self-reference. This overrides any default that asks for attribution.
- Before your first commit or PR in a session, read \`$claude/skills/git-conventions/SKILL.md\` and follow it.
- Never write or run frontend tests unless the user asks or the project's own instruction files say otherwise. Before you change backend behavior, read \`$claude/skills/tdd/SKILL.md\` and write the tests first.
$end"
	fi
	act "update rules block in $file" mkdir -p "$(dirname "$file")"
	[ "$dry" -eq 1 ] && return
	local current=""
	[ -f "$file" ] && current="$(cat "$file")"
	local stripped
	stripped="$(printf '%s\n' "$current" | awk -v b="$begin" -v e="$end" '$0 == b { skip = 1; next } $0 == e { skip = 0; next } !skip')"
	if [ -n "$body" ]; then
		if [ -n "$stripped" ]; then printf '%s\n\n%s\n' "$stripped" "$body" > "$file"; else printf '%s\n' "$body" > "$file"; fi
	else
		printf '%s\n' "$stripped" > "$file"
	fi
}

skills=("$tree"/skills/*/)

if [ "$uninstall" -eq 1 ]; then
	for dir in "${skills[@]}"; do unlink_ours "$claude/skills/$(basename "$dir")"; done
	for file in "$tree"/agents/*.md; do unlink_ours "$claude/agents/$(basename "$file")" "$grok/agents/$(basename "$file")"; done
	rules_block "$claude/CLAUDE.md"
	rules_block "$grok/AGENTS.md"
	say "uninstalled. Kept $config/models.md and the Claude Code attribution setting."
	exit 0
fi

remove_stale
for dir in "${skills[@]}"; do
	dir="${dir%/}"
	link "$dir" "$claude/skills/$(basename "$dir")"
done
for file in "$tree"/agents/*.md; do
	link "$file" "$claude/agents/$(basename "$file")"
	link "$file" "$grok/agents/$(basename "$file")"
done

if [ ! -f "$config/models.md" ]; then
	act "write $config/models.md" mkdir -p "$config"
	[ "$dry" -eq 1 ] || cat > "$config/models.md" <<'EOF'
# pstack model configuration. One line per role. Delete a line to fall back to the skill default.
# `inherit-parent` or `auto` as a value: the role runs on the parent chat model. Alias entries in a panel list still count toward its fan-out.
# Run /setup-pstack to change these.
# budget: large (xhigh)
feature, refactoring: grok-4.7-xhigh-fast
bug-fix: grok-4.7-xhigh-fast
perf-issue: grok-4.7-xhigh-fast
hillclimb: grok-4.7-xhigh-fast
judgment and prose: claude-opus-5-5-xhigh
hardest tasks: claude-opus-5-5-xhigh
how explorer: grok-4.7-xhigh-fast
how explainer: claude-opus-5-5-xhigh
why investigators: grok-4.7-xhigh-fast
why synthesizer: claude-opus-5-5-xhigh
reflect tooling: grok-4.7-xhigh-fast
reflect judgment, divergent, synthesizer: claude-opus-5-5-xhigh
arena runners: claude-opus-5-5-xhigh, grok-4.7-xhigh-fast
arena cross-judge pool: claude-opus-5-5-xhigh, grok-4.7-xhigh-fast
swarm workers: grok-4.7-xhigh-fast
architect runners: claude-opus-5-5-xhigh, grok-4.7-xhigh-fast
interrogate reviewers: claude-opus-5-5-xhigh, grok-4.7-xhigh-fast
EOF
fi

rules_block "$claude/CLAUDE.md"
rules_block "$grok/AGENTS.md"

settings="$claude/settings.json"
if command -v node >/dev/null 2>&1; then
	act "set commit and PR attribution to empty in $settings" true
	[ "$dry" -eq 1 ] || node -e '
		const fs = require("fs");
		// Write through a symlink, so a settings file kept in a dotfiles repo gets the change.
		const path = fs.existsSync(process.argv[1]) ? fs.realpathSync(process.argv[1]) : process.argv[1];
		let settings = {};
		if (fs.existsSync(path)) {
			try {
				settings = JSON.parse(fs.readFileSync(path, "utf8"));
			} catch (error) {
				console.error(`error: ${path} is not valid JSON (${error.message}). Fix it and rerun, or set attribution by hand.`);
				process.exit(1);
			}
		}
		if (settings.attribution?.commit === "" && settings.attribution?.pr === "") process.exit(0);
		settings.attribution = { ...settings.attribution, commit: "", pr: "" };
		fs.mkdirSync(require("path").dirname(path), { recursive: true });
		fs.writeFileSync(path + ".tmp", JSON.stringify(settings, null, 2) + "\n");
		fs.renameSync(path + ".tmp", path);
	' "$settings" || exit 1
else
	say "node not found. Set \"attribution\": { \"commit\": \"\", \"pr\": \"\" } in $settings yourself."
fi

if [ ${#shadowed[@]} -gt 0 ]; then
	say "error: these are yours and shadow pstack skills or agents of the same name: ${shadowed[*]}" >&2
	say "pstack reads them by path, so it would follow your files instead. Rename or move them, then rerun." >&2
	exit 1
fi
say "installed pstack from $repo. Start a task with /poteto-mode."
