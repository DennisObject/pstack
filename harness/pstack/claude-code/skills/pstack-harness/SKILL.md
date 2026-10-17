---
name: pstack-harness
description: "Maps the Cursor names in pstack skills to Claude Code, Grok, and T3 Code. Read it once per session before you follow any pstack skill outside Cursor."
disable-model-invocation: true
---

# pstack outside Cursor

pstack skills use Cursor names, such as the `Task` tool, Cursor model slugs, and the `pstack-models.mdc` rule. This skill maps them to the harness you run in. In Cursor, stop here. Nothing below applies.

## Find your harness

Decide from the tools you have, not from memory.

- You have an `Agent` tool. You run in Claude Code. Read [references/claude-code.md](references/claude-code.md).
- You have a `spawn_subagent` tool. You run in Grok. Read [references/grok.md](references/grok.md).
- You also have `delegate_task` and `orchestrator_capabilities` from the `t3-code` MCP server. You run inside T3 Code, which adds subagents on other providers. Read [references/t3-code.md](references/t3-code.md) as well.

If none fits, use the rules below, and name each step you could not map in your reply.

## Rules for every harness

**Run another pstack skill by reading its `SKILL.md`.** Skills sit side by side, so the **how** skill is `../how/SKILL.md` from this file. Most pstack skills set `disable-model-invocation: true`. That hides them from the skill tool, not from you, so read the file instead of giving up.

**Read the model config once per session.** It lives at `~/.config/pstack/models.md` and holds the role lines that Cursor keeps in `~/.cursor/rules/pstack-models.mdc`, in the same format, without frontmatter. A missing file or a missing line means the skill's default. `/setup-pstack` writes this file outside Cursor. Never copy role lines into `AGENTS.md` or `CLAUDE.md`.

**Keep model slugs in Cursor form.** Skills and the config name models as `claude-opus-5-5-xhigh` or `grok-4.7-xhigh-fast`. Read a slug as family, version, effort, and an optional `-fast`. Your harness reference turns it into spawn parameters.

**Spawn each role on its configured family, in this order:**

1. Your harness's own subagent tool, when it can run that family.
2. T3's `delegate_task`, when T3 is present.
3. The other provider's CLI in headless mode, for read-only work such as a review or an explanation. Your harness reference gives the command.
4. Your own model. Say so in the reply.

Never drop a seat without saying so. A review panel that should hold two model families and holds one says that in its output, because model diversity is what makes the review adversarial.

**Ask questions and track todos with your harness's tools.** Your reference names them. With no todo tool, keep the list in your reply and update it at each phase.

**Read the project's rules before code.** Cursor loads `.cursor/rules` by itself. Claude Code and Grok load only some instruction files, so run the **project-conventions** skill before you write code. It reads all of them.

**Use the cursor-team-kit skills that pstack relies on.** The portable install puts `deslop`, `control-ui`, and `control-cli` next to pstack, so read them as `../deslop/SKILL.md` and so on. If one is missing, do its job by hand and say so.

**Tell the user what to type.** The portable install puts pstack in `~/.claude/skills/`, so commands have no prefix, as in `/poteto-mode`. A Claude Code plugin install prefixes them, as in `/pstack:poteto-mode`.

## Cursor-only features

- Bugbot means any review bot on the PR, such as Copilot review, CodeRabbit, or a security scanner. Triage its comments with the same rubric.
- A Cursor cloud agent becomes a subagent in its own git worktree. Name the branch or commit it checks out.
- Cursor Automations become T3's `schedule_task` when T3 is present. Otherwise skip the step and say so.
- Custom Modes do not exist. Start each new task with `/poteto-mode`.
- Cursor's pull request tool does not exist. Use `gh`.
- Cursor's `/loop` and `create-skill` map per harness. Your reference has the row.
