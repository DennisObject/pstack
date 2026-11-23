# pstack in Claude Code

pstack skills use Cursor names. In Claude Code, read this file once per session after [the harness skill](../SKILL.md), then map each Cursor name in a skill with the tables below. `<pstack>/skills/` means the folder that holds the harness skill. If a Cursor field has no row, drop it and say so. Never pass a field or value the tool schema rejects.

## Tools

| Cursor | Claude Code |
| --- | --- |
| `Task` | `Agent` |
| `AskQuestion` | `AskUserQuestion`. In `-p` mode it is absent, so ask in plain text. |
| Open a todolist | Use `TodoWrite` if the session offers it. Otherwise keep the list in your reply and update it at each phase. |
| Run another pstack skill (`/name` or "the **name** skill") | `Read` `<pstack>/skills/<name>/SKILL.md` and follow it. The `Skill` tool refuses most pstack skills. When you tell the user to type it, write `/<name>` for the portable install and `/pstack:<name>` for the plugin install. |
| `Grep`, `Glob` | `Bash` with `rg` when the session has no `Grep` or `Glob`. |

## Subagent fields

| Cursor | Claude Code |
| --- | --- |
| `subagent_type: generalPurpose` | `subagent_type: "general-purpose"` |
| `poteto-agent`, `comment-sicko` | `poteto-agent`, `comment-sicko` with the portable install. `pstack:poteto-agent`, `pstack:comment-sicko` with the plugin install. |
| `readonly: true` | `subagent_type: "Explore"`. It keeps `Bash`, so the brief also says "do not edit files", and you check `git status` afterward. |
| `readonly: false` | `general-purpose`. It keeps the session's MCP servers. |
| `environment: "cloud"` | `isolation: "worktree"`. Name the branch or commit the worker checks out. |
| `environment: "local"` | Omit. |
| `cloud_base_branch: <b>` | Tell the worker to check out `<b>` first. |
| `run_in_background: true` | Omit. Subagents run in the background by default and notify you when they finish. |
| `resume` | Spawn a new agent and paste the earlier result into its brief. |
| `file_attachments` | List the paths in the brief. |

## Models

| Cursor | Claude Code |
| --- | --- |
| `claude-<family>-<version>-<effort>[-fast]`, such as `claude-opus-5-5-xhigh` | `model` from the family: `opus`, `sonnet`, `haiku`, or `fable`. Drop `-fast`. Pass the slug's effort, but never above `high`. `xhigh` and `max` become `high`. |
| A `grok-*` slug | Never run Grok. Run the seat on `model: "sonnet"` at `high`, and drop `-fast`. Do not copy a Grok `xhigh` onto Claude. |
| A `gpt-*` or other non-Claude slug | Run the seat on `model: "sonnet"` at the slug's effort, capped at `high`. Drop `-fast`. |
| `auto` or `inherit-parent` | Omit `model`. |
| The `pstack-models.mdc` rule | Claude Code does not load it. Read and write `~/.config/pstack/models.md` instead, which holds the same role lines without frontmatter. [The harness skill](../SKILL.md) says how `setup-pstack` writes it. Never put its role lines in `CLAUDE.md` or `AGENTS.md`. |

## Paths

| Cursor | Claude Code |
| --- | --- |
| `.cursor/skills/`, `~/.cursor/skills/` | `.claude/skills/`, `~/.claude/skills/` |
| `~/.cursor/plugins/`, `.cursor-plugin/plugin.json` | `~/.claude/plugins/`, `.claude-plugin/plugin.json` |
| `.cursor/rules/*.mdc`, always-applied rules | `CLAUDE.md`, or `AGENTS.md` when no `CLAUDE.md` exists. Claude Code never reads `.mdc` files. The **project-conventions** skill reads every instruction file, so a project's `AGENTS.md` still applies. |
| Transcripts in `~/.cursor/projects/<slug>/agent-transcripts/` | `~/.claude/projects/<slug>/<session>.jsonl`. The slug is the workspace path with each `/` and `.` changed to `-`, so `/Users/you/proj` is `-Users-you-proj`. The newest `.jsonl` directly in that folder is the current session. Its `<session>/subagents/` folder holds subagent transcripts. Read only this workspace's folder. |

## Commands and companion skills

| Cursor | Claude Code |
| --- | --- |
| Cursor's `/loop` command | The `loop` skill when the session lists it. A finished subagent wakes you, so end the turn instead of polling. |
| Cursor's built-in `create-skill` | The `skill-creator` skill when the session lists it. Otherwise follow the authoring playbook alone. |
| `deslop`, `control-ui`, `control-cli` from `cursor-team-kit` | Installed next to pstack by the portable install. Read `<pstack>/skills/<name>/SKILL.md`. |

## Cursor-only features

Automations, Bugbot, Cursor cloud agents, and Cursor's pull request tool have no Claude Code equivalent. Map them per [the harness skill](../SKILL.md), or say so, skip that step, and continue.
