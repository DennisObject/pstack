---
name: pstack-harness
description: "Maps the Cursor names in pstack skills to Claude Code (including T3 Code threads), Codex, and Grok. Read it once per session before you follow any pstack skill outside Cursor."
disable-model-invocation: true
---

# pstack outside Cursor

pstack skills use Cursor names, such as the `Task` tool, Cursor model slugs, and the `pstack-models.mdc` rule. This skill maps them to the harness you run in. In Cursor, stop here. Nothing below applies.

## Find your harness

pstack runs in Claude Code, Codex, and Grok. Read the reference for the harness you run in.

- **Claude Code:** [references/claude-code.md](references/claude-code.md). If you also have tools from the `t3-code` MCP server, you run in a T3 Code thread, so read [references/t3-code.md](references/t3-code.md) as well.
- **Codex:** [references/codex.md](references/codex.md). Your subagent tool is `spawn_agent`.
- **Grok:** [references/grok.md](references/grok.md). Your subagent tool is `task`.

**Name the harness in every brief you write,** as in "Harness: Codex. pstack skills are in `<path>`." A subagent then reads the right adapter without guessing.

## Rules for every harness

**Run another pstack skill by reading its `SKILL.md`.** Skills sit side by side, so the **how** skill is `../how/SKILL.md` from this file. Most pstack skills set `disable-model-invocation: true`. That hides them from the skill tool, not from you, so read the file instead of giving up.

**Read the model config once per session.** It lives at `~/.config/pstack/models.md` and holds the role lines that Cursor keeps in `~/.cursor/rules/pstack-models.mdc`, in the same format, without frontmatter. A missing file or a missing line means the skill's default. Never copy role lines into `AGENTS.md` or `CLAUDE.md`.

**Keep model slugs in Cursor form.** Skills and the config name models as `claude-opus-5-5-xhigh`. Read a slug as family, version, effort, and an optional `-fast`. Your harness reference turns it into spawn parameters. Upstream skills name Grok slugs as defaults for code and exploration seats. Your reference says how to run those on Claude.

**Spawn every seat with your harness's subagent tool.** That is `Agent` in Claude Code, `spawn_agent` in Codex, and `task` in Grok. Never drop a seat without saying so.

**Decide whether you can spawn from your tools, not from your role.** If your subagent tool is in your tool list, run every panel and delegate the skill asks for, even when your brief calls you a sub-agent. Without it, leave the fan-out to your parent, or do the slices yourself one after another and say so.

**Ask questions and track todos with your harness's tools.** Your reference names them. With no todo tool, keep the list in your reply and update it at each phase.

**Read the project's rules before code.** Cursor loads `.cursor/rules` by itself. Claude Code, Codex, and Grok each load only some instruction files, so run the **project-conventions** skill before you write code. It reads all of them.

**Use the cursor-team-kit skills that pstack relies on.** The portable install puts `deslop`, `control-ui`, and `control-cli` next to pstack, so read them as `../deslop/SKILL.md` and so on. If one is missing, do its job by hand and say so.

**Tell the user what to type.** The portable install puts pstack in `~/.claude/skills/`, so Claude Code and Grok commands have no prefix, as in `/poteto-mode`. A Claude Code plugin install prefixes them, as in `/pstack:poteto-mode`. In Codex, write `$poteto-mode`.

## Run setup-pstack outside Cursor

Follow the **setup-pstack** skill with three changes.

- **Detect models** from your subagent tool. In Claude Code that is the `Agent` tool: `opus`, `sonnet`, `haiku`, and `fable`, each at the efforts it accepts. Offer only Claude slugs there. Codex and Grok cannot run Claude models, so write no model lines and say that every seat runs on the session model. Where the skill defaults name a Grok slug, use `claude-haiku-5-5` for `how explorer` and `claude-sonnet-5-5` for every other role.
- **Write** `~/.config/pstack/models.md` with the same lines, without frontmatter.
- **Validate** each slug against what you detected, by model and effort.

## Cursor-only features

- Bugbot means any review bot on the PR, such as Copilot review, CodeRabbit, or a security scanner. Triage its comments with the same rubric.
- A Cursor cloud agent becomes a subagent in its own git worktree. Name the branch or commit it checks out.
- Cursor Automations become T3's `schedule_task` in a T3 thread. Otherwise skip the step and say so.
- Custom Modes do not exist. Start each new task with `/poteto-mode`.
- Cursor's pull request tool does not exist. Use `gh`.
- Cursor's `/loop` and `create-skill` map in your reference.
