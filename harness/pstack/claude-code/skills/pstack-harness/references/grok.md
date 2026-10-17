# pstack in Grok

pstack skills use Cursor names. In Grok, read this file once per session after [the harness skill](../SKILL.md), then map each Cursor name in a skill with the tables below. `<pstack>/skills/` means the folder that holds the harness skill. If a Cursor field has no row, drop it and say so. Never pass a field or value the tool schema rejects.

## Tools

| Cursor | Grok |
| --- | --- |
| `Task` | `spawn_subagent`. Read a background result with `get_command_or_subagent_output`. |
| `AskQuestion` | `ask_user_question`. In a headless `grok -p` run it may be absent, so ask in plain text. |
| Open a todolist | `todo_write`. |
| Run another pstack skill (`/name` or "the **name** skill") | Read `<pstack>/skills/<name>/SKILL.md` and follow it. When you tell the user to type it, write `/<name>`. |
| `Grep`, `Glob` | Your search tools, or `rg` through the shell. |

## Subagent fields

| Cursor | Grok |
| --- | --- |
| `subagent_type: generalPurpose` | Omit `subagent_type`. Grok defaults to `general-purpose`. |
| `poteto-agent`, `comment-sicko` | `subagent_type: "poteto-agent"` or `"comment-sicko"` when the tool lists them. The portable install puts both in `~/.grok/agents/`. If the tool does not list them, omit `subagent_type` and start the brief with "Read `<path to the agent file>` in full and act as it says." |
| `readonly: true` | Your model cannot pick Grok's read-only `explore` type. Omit `subagent_type`, write "Do not edit files" in the brief, and check `git status` afterward. |
| `readonly: false` | Omit `subagent_type`. The subagent keeps the session's MCP servers. |
| `environment: "cloud"` | `isolation: "worktree"`. The result names the worktree path. Name the branch or commit the worker checks out. |
| `environment: "local"` | Omit `isolation`. |
| `cloud_base_branch: <b>` | Tell the worker to check out `<b>` first. |
| `run_in_background: true` | `run_in_background: true`. It is also the default. |
| `resume` | `resume_from: <subagent id>` works only for a finished subagent of the same type in this session. Otherwise spawn a new agent and paste the earlier result into its brief. |
| `file_attachments` | List the paths in the brief. |

**A Grok subagent cannot spawn subagents.** The depth limit is one. When a skill tells a delegate to fan out, the parent fans out instead, or the delegate does the slices itself one after another and says so. The parent owns every panel: `interrogate` reviewers, `arena` runners, `swarm` workers, and `how` explorers.

## Models

| Cursor | Grok |
| --- | --- |
| `grok-<version>-<effort>[-fast]`, such as `grok-4.7-xhigh-fast` | Inside T3, spawn it with `delegate_task` per [t3-code.md](t3-code.md), because `spawn_subagent` cannot set the effort and often cannot set the model. Without T3, use `spawn_subagent`, set `model` when its description lists models (`grok-<version>-build-fast` for a `-fast` slug, `grok-<version>` otherwise), and say that the seat ran at the session's effort. |
| A `claude-*` slug, such as `claude-opus-5-5-xhigh` | `spawn_subagent` cannot run it. Inside T3, spawn it with `delegate_task` per [t3-code.md](t3-code.md). Otherwise, for read-only work, run the Claude CLI headless (below). Otherwise run the role on the session model and say so. |
| A `gpt-*` or other slug | Run the role on the session model and say so. |
| `auto` or `inherit-parent` | Omit `model`. |
| The `pstack-models.mdc` rule | Grok does not load it. Read and write `~/.config/pstack/models.md` instead, which holds the same role lines without frontmatter. [The harness skill](../SKILL.md) says how `setup-pstack` writes it. Never put its role lines in `AGENTS.md`. |

Opus is pstack's default for judgment: the design synthesis in `architect`, the lead verdict in `interrogate`, the explainer in `how`, and prose such as a PR body. When you run as the parent on Grok, spawn those roles on their configured Claude model through T3 instead of doing them yourself. Then review what comes back. You still own the result.

## Paths

| Cursor | Grok |
| --- | --- |
| `.cursor/skills/`, `~/.cursor/skills/` | `.grok/skills/`, `~/.grok/skills/`, and `~/.claude/skills/`. Grok reads all three. |
| `~/.cursor/plugins/`, `.cursor-plugin/plugin.json` | `~/.grok/plugins/`. Grok also reads Claude-style plugins. |
| `.cursor/rules/*.mdc`, always-applied rules | `AGENTS.md`, `Agents.md`, `AGENT.md`, or `Claude.md` in each directory from the repo root down to the working directory, plus global rules in `~/.grok/`. Grok cuts each file at 10,000 characters. The **project-conventions** skill reads the rest. |
| Transcripts in `~/.cursor/projects/<slug>/agent-transcripts/` | `~/.grok/sessions/<url-encoded working directory>/<session id>/updates.jsonl`, with the raw messages in `chat_history.jsonl`. Subagent sessions live in the same tree, and the parent's `subagents/` folder holds their metadata. Read only this workspace's folder. |

## Commands and companion skills

| Cursor | Grok |
| --- | --- |
| Cursor's `/loop` command | Grok has no `/loop`. Inside T3, a delegated task wakes you when it finishes, and `schedule_task` gives a timer. Otherwise keep driving in this turn and checkpoint with the **show-me-your-work** skill. |
| Cursor's built-in `create-skill` | Grok's bundled `create-skill` skill. |
| `deslop`, `control-ui`, `control-cli` from `cursor-team-kit` | Installed next to pstack by the portable install. Read `<pstack>/skills/<name>/SKILL.md`. |

## Headless Claude

For a read-only seat, such as an `interrogate` reviewer or a `how` explainer, run Claude from the shell and read its stdout as the subagent's report:

```bash
claude -p --model opus --effort xhigh --permission-mode plan --output-format text < /tmp/<brief>.md
```

Use the slug's family as `--model` (`opus`, `sonnet`, `haiku`, `fable`) and its effort as `--effort`. Write the brief to a file and pass it on stdin, so no shell quoting or argument limit touches it. `--permission-mode plan` keeps the run read-only. Check `git status` afterward anyway. Never use this path for a seat that edits files.

## Cursor-only features

Automations, Bugbot, Cursor cloud agents, and Cursor's pull request tool have no Grok equivalent. Map them per [the harness skill](../SKILL.md), or say so, skip that step, and continue.
