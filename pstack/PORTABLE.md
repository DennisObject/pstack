# Portable pstack

This fork runs [pstack](./README.md) in Claude Code, Grok, and T3 Code with the same playbooks, skills, and model roles it uses in Cursor. It also adds house rules for git, testing, reuse, and comments. The upstream skills stay as poteto wrote them, apart from a few short edits listed at the end, so upstream updates merge cleanly.

## Install

```bash
git clone <this fork> ~/Projects/pstack
~/Projects/pstack/scripts/install-portable-pstack.sh
```

The script is safe to rerun and never replaces a skill or agent you own. It does five things:

- Links every pstack skill, plus `deslop`, `control-ui`, and `control-cli` from `cursor-team-kit`, into `~/.claude/skills/`. Claude Code and Grok both read that folder.
- Links the `poteto-agent` and `comment-sicko` agents into `~/.claude/agents/` and `~/.grok/agents/`.
- Writes `~/.config/pstack/models.md` with the default role models, if the file does not exist.
- Adds a three-line rules block to `~/.claude/CLAUDE.md` and `~/.grok/AGENTS.md`: no AI attribution, Conventional Commits, and no frontend tests unless asked. These apply even outside `/poteto-mode`.
- Sets `"attribution": { "commit": "", "pr": "" }` in `~/.claude/settings.json`, so Claude Code adds no co-author trailer.

`--dry-run` prints the plan. `--uninstall` removes the links and the rules block.

## Use

Start each task with `/poteto-mode`, the goal, and how to tell it is done.

```
/poteto-mode group windows show stale HP when someone else damages a selected target. fix it. done means a regression test that failed before the fix passes, and the PR body is ready.
```

The mode picks a playbook. For a feature or a bug fix it now runs, in order:

1. **project-conventions.** Reads every `AGENTS.md` and `CLAUDE.md` on the path, the lint and CI config, and nearby code. Returns the rules and the exact commands.
2. **reuse-scan.** Searches the codebase four ways for code that already does the job. Returns a reuse brief that every code delegate must follow.
3. **tdd.** For backend behavior, writes the tests from the requirement and commits them red. The implementer turns them green without touching them, and `red-green.sh` proves it from git history. Frontend code gets no tests.
4. **interrogate.** Before every PR, reviewers from at least two model families try to break the diff.
5. **git-conventions.** Conventional Commits, a PR body with only Why, Testing, and Deployment, and `check-message.sh` on every message.

## Update from upstream

```bash
scripts/sync-upstream.sh
```

It merges `upstream/main`, rebuilds the generated tree with this fork's generator, and runs every script test. On a real conflict it lists the files. Resolve them, stage them, and run `scripts/sync-upstream.sh --continue`. The links follow the checkout, so rerun the install only when a skill is added or removed.

## Models

`~/.config/pstack/models.md` holds one line per role in Cursor's slug form, such as `grok-4.7-xhigh-fast` or `claude-opus-5-5-xhigh`. `/setup-pstack` rewrites it. The defaults follow upstream: Grok writes code, and Opus does design synthesis, review judgment, and prose.

How a role reaches its model depends on where the parent runs.

| Parent | Claude roles | Grok roles |
| --- | --- | --- |
| Claude Code in T3 | Native `Agent` tool | T3 `delegate_task` |
| Grok in T3 | T3 `delegate_task` | Native `spawn_subagent` |
| Claude Code alone | Native `Agent` tool | `grok -p` headless for read-only seats, else the session model |
| Grok alone | `claude -p` headless for read-only seats, else the session model | Native `spawn_subagent` |

Run inside T3 when you can. It is the only setup where every role runs on its configured family, which is what makes a Grok-led run trustworthy: Opus judges the design and the review, and a model from another family reviews every diff.

## Project rules belong in AGENTS.md

pstack carries the workflow. Each repository's `AGENTS.md` carries the facts: commands, architecture rules, and style, such as "PSR-12, enforced by `composer lint`". Keep these points in mind:

- Claude Code loads `AGENTS.md` only in a directory without its own `CLAUDE.md`. Make each `CLAUDE.md` a single line, `@AGENTS.md`, or delete it.
- Grok reads `AGENTS.md` and `Claude.md` and cuts each at 10,000 characters. Keep the file short, and link to longer references.
- Put a rule a tool can enforce into the tool's config, and name the command in `AGENTS.md`.
- Drop workflow rules that pstack now covers, such as test-first, comments, and git, unless the project needs a different rule. A project rule beats a pstack default.

[`project-conventions/references/agents-md-template.md`](./skills/project-conventions/references/agents-md-template.md) has a template.

## What differs from upstream

New files:

- `skills/pstack-harness/` maps Cursor names to Claude Code, Grok, and T3 Code. It holds upstream's Claude Code adapter, moved from `docs/harness/`.
- `skills/git-conventions/`, `skills/project-conventions/`, and `skills/reuse-scan/`.
- `skills/git-conventions/scripts/check-message.sh` and `skills/tdd/scripts/red-green.sh`, with tests.
- `../scripts/install-portable-pstack.sh` and `../scripts/sync-upstream.sh`, with tests.

Edited upstream files:

- `skills/tdd/SKILL.md` makes backend changes test-first by default and leaves frontend code untested.
- `skills/poteto-mode/SKILL.md` adds three triggers (project conventions and reuse, TDD, git) and allows a short comment on genuinely complex code.
- `playbooks/feature.md`, `bug-fix.md`, and `refactoring.md` add those steps. `opening-a-pr.md` adds the cross-family review and the short PR body.
- `agents/comment-sicko.md` keeps tool-read annotations and the short comment above.
- `agents/poteto-agent.md`, `skills/poteto-help/SKILL.md`, and `skills/interrogate/references/code-quality-review.md` get one or two lines each.
- `../scripts/generate-pstack-harness-trees.mjs` points every generated skill at the harness skill and checks both adapters.

## Limits

- A Grok subagent cannot spawn subagents, so the parent runs every review panel.
- Grok's native `spawn_subagent` has no effort setting. A Grok seat that needs a specific effort runs through T3.
- Bugbot, Cursor cloud agents, Cursor Automations, and Custom Modes have no equivalent. The harness skill maps each to the nearest substitute or skips it. The `benny` automation pack stays Cursor-only.
