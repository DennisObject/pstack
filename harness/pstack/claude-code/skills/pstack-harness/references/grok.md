# pstack in Grok

pstack skills use Cursor names. In Grok, read this file once per session after [the harness skill](../SKILL.md), then map each Cursor name in a skill with the tables below. `<pstack>/skills/` means the folder that holds the harness skill. If a Cursor field has no row, drop it and say so. Never pass a field or value the tool schema rejects.

## Tools

| Cursor | Grok |
| --- | --- |
| `Task` | `task`. Collect results with `get_task_output` and stop one with `kill_task`. It needs subagents on, which is the default. When the session has no `task`, leave the fan-out to your parent, or do the slices yourself one after another and say so. |
| `AskQuestion` | Ask in plain text. Grok has no question tool. |
| Open a todolist | `todo_write`. |
| Run another pstack skill (`/name` or "the **name** skill") | `read_file` `<pstack>/skills/<name>/SKILL.md` and follow it. When you tell the user to type it, write `/<name>`. |
| `Grep`, `Glob` | `grep_search` and `list_dir`, or `bash` with `rg`. |

## Subagent fields

| Cursor | Grok |
| --- | --- |
| `subagent_type: generalPurpose` | The default subagent type. |
| `poteto-agent`, `comment-sicko` | Grok loads `~/.claude/agents/`, so use `poteto-agent` and `comment-sicko` by name. When the session does not list them, tell the delegate to read `agents/<name>.md`, in the folder next to `<pstack>/skills/` in the pstack checkout, before any work. |
| `readonly: true` | The `explore` subagent type. It may keep `bash`, so the brief also says "do not edit files", and you check `git status` afterward. |
| `readonly: false` | The default subagent type. |
| `environment: "cloud"` | A worktree you create first with `git worktree add`, which the brief names. Name the branch or commit the worker checks out. |
| `environment: "local"` | Omit. |
| `cloud_base_branch: <b>` | Tell the worker to check out `<b>` first. |
| `run_in_background: true` | Use the task's background option when the schema has one. Otherwise omit. |
| `resume` | Spawn a new subagent and paste the earlier result into its brief. |
| `file_attachments` | List the paths in the brief. |

## Models

| Cursor | Grok |
| --- | --- |
| `claude-<family>-<version>-<effort>[-fast]`, such as `claude-opus-5-5-xhigh` | Grok cannot run Claude models. A subagent inherits the session model, and only a `[subagents.models]` pin in `~/.grok/config.toml` changes that. Run the seat on the session model and say so. |
| A `grok-*`, `gpt-*`, or other non-Claude slug | Same: the session model, unless `[subagents.models]` pins the agent. |
| `auto` or `inherit-parent` | Omit the model. |
| The `pstack-models.mdc` rule | Grok does not load it. Read and write `~/.config/pstack/models.md` instead, which holds the same role lines without frontmatter. Never put its role lines in `AGENTS.md`. |

## Paths

| Cursor | Grok |
| --- | --- |
| `.cursor/skills/`, `~/.cursor/skills/` | `.grok/skills/`, `~/.grok/skills/`. Grok also reads `.claude/skills/` and `~/.claude/skills/`. |
| `~/.cursor/plugins/`, `.cursor-plugin/plugin.json` | `~/.grok/plugins/`. Grok has no pstack plugin, so skip plugin steps and say so. |
| `.cursor/rules/*.mdc`, always-applied rules | `AGENTS.md` or `CLAUDE.md`, and `~/.grok/rules/*.md` for user-level rules. Grok never reads `.mdc` files. The **project-conventions** skill reads every instruction file. |
| Transcripts in `~/.cursor/projects/<slug>/agent-transcripts/` | `~/.grok/sessions/<url-encoded-cwd>/<session-id>/updates.jsonl`. The folder name is the workspace path with `/` encoded as `%2F`, so `/home/you/proj` is `%2Fhome%2Fyou%2Fproj`. Its `subagents/` folder holds child sessions. Read only this workspace's folder, newest session first. |

## Commands and companion skills

| Cursor | Grok |
| --- | --- |
| Cursor's `/loop` command | No equivalent. End the turn when a subagent will wake you, otherwise do one pass and say what is left. |
| Cursor's built-in `create-skill` | The `skill-creator` skill when the session lists it. Otherwise follow the authoring playbook alone. |
| `deslop`, `control-ui`, `control-cli` from `cursor-team-kit` | Installed next to pstack. Read `<pstack>/skills/<name>/SKILL.md`. |

## Cursor-only features

Automations, Bugbot, Cursor cloud agents, and Cursor's pull request tool have no Grok equivalent. Map them per [the harness skill](../SKILL.md), or say so, skip that step, and continue.
