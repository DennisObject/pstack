# pstack in Codex

pstack skills use Cursor names. In Codex, read this file once per session after [the harness skill](../SKILL.md), then map each Cursor name in a skill with the tables below. `<pstack>/skills/` means the folder that holds the harness skill. If a Cursor field has no row, drop it and say so. Never pass a field or value the tool schema rejects.

## Tools

| Cursor | Codex |
| --- | --- |
| `Task` | `spawn_agent`. Collect results with `wait_agent` and free the slot with `close_agent`. Follow the schema the session shows. When the session has no `spawn_agent`, leave the fan-out to your parent, or do the slices yourself one after another and say so. |
| `AskQuestion` | `request_user_input`. When the session does not offer it, ask in plain text. |
| Open a todolist | `update_plan`. Otherwise keep the list in your reply and update it at each phase. |
| Run another pstack skill (`/name` or "the **name** skill") | `Read` `<pstack>/skills/<name>/SKILL.md` and follow it. When you tell the user to type it, write `$<name>`, or `/skills` to pick it. |
| `Grep`, `Glob` | The shell with `rg`. |

## Subagent fields

| Cursor | Codex |
| --- | --- |
| `subagent_type: generalPurpose` | The default agent role. |
| `poteto-agent`, `comment-sicko` | Codex does not load Claude agent files. Tell the delegate to read `agents/<name>.md`, in the folder next to `<pstack>/skills/` in the pstack checkout, before any work. Resolve the skill symlink to find the checkout. |
| `readonly: true` | A read-only role or sandbox when the session offers one. Otherwise the brief says "do not edit files", and you check `git status` afterward. |
| `readonly: false` | The default agent role. |
| `environment: "cloud"` | A worktree you create first with `git worktree add`, which the brief names. Name the branch or commit the worker checks out. |
| `environment: "local"` | Omit. |
| `cloud_base_branch: <b>` | Tell the worker to check out `<b>` first. |
| `run_in_background: true` | Omit. Spawn, then `wait_agent` only when nothing else is left to do. |
| `resume` | `send_input` to the same agent while it is open. Otherwise spawn a new agent and paste the earlier result into its brief. |
| `file_attachments` | List the paths in the brief. |

## Models

| Cursor | Codex |
| --- | --- |
| `claude-<family>-<version>-<effort>[-fast]`, such as `claude-opus-5-5-xhigh` | Codex cannot run Claude models. When the session model is Grok, run the seat there, and Grok may stay at `xhigh`. When `spawn_agent` takes a model override, pick a GPT model from the session's own list at `high` or below, and drop `-fast`. Say so. |
| A `gpt-*` slug | Pick that GPT model, or the session model when it is GPT. Cap the effort at `high`. Drop `-fast`. |
| A `grok-*` or other non-Claude slug | Keep Grok at `xhigh` when the session is Grok. A GPT substitute stays at `high` or below. |
| `auto` or `inherit-parent` | Omit the model. |
| The `pstack-models.mdc` rule | Codex does not load it. Read and write `~/.config/pstack/models.md` instead, which holds the same role lines without frontmatter. Never put its role lines in `AGENTS.md`. |

## Paths

| Cursor | Codex |
| --- | --- |
| `.cursor/skills/`, `~/.cursor/skills/` | `.agents/skills/`, `~/.agents/skills/` |
| `~/.cursor/plugins/`, `.cursor-plugin/plugin.json` | `~/.codex/plugins/`. Codex has no pstack plugin, so skip plugin steps and say so. |
| `.cursor/rules/*.mdc`, always-applied rules | `AGENTS.md`, and `~/.codex/AGENTS.md` for user-level rules. Codex never reads `.mdc` files. The **project-conventions** skill reads every instruction file, so a project's `CLAUDE.md` still applies. |
| Transcripts in `~/.cursor/projects/<slug>/agent-transcripts/` | `~/.codex/sessions/<yyyy>/<mm>/<dd>/rollout-*.jsonl`. The first line is a `session_meta` record whose `payload.cwd` names the workspace. Read only rollouts for this workspace, newest first. |

## Commands and companion skills

| Cursor | Codex |
| --- | --- |
| Cursor's `/loop` command | No equivalent. End the turn when a subagent will wake you, otherwise do one pass and say what is left. |
| Cursor's built-in `create-skill` | The `skill-creator` skill when the session lists it. Otherwise follow the authoring playbook alone. |
| `deslop`, `control-ui`, `control-cli` from `cursor-team-kit` | Installed next to pstack. Read `<pstack>/skills/<name>/SKILL.md`. |

## Cursor-only features

Automations, Bugbot, Cursor cloud agents, and Cursor's pull request tool have no Codex equivalent. Map them per [the harness skill](../SKILL.md), or say so, skip that step, and continue.
