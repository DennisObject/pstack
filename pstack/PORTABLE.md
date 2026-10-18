# Portable pstack

This fork runs [pstack](./README.md) in Claude Code, Grok, and T3 Code with the same playbooks, skills, and model roles it uses in Cursor. It also adds house rules for git, testing, reuse, and comments. The upstream skills stay as poteto wrote them, apart from a few short edits listed at the end, so upstream updates merge cleanly.

## Install

```bash
git clone <this fork> ~/Projects/pstack
~/Projects/pstack/scripts/install-portable-pstack.sh
```

The script is safe to rerun and never replaces a skill or agent you own. It does five things:

- Links every skill of the generated tree into `~/.claude/skills/`. The tree also carries `deslop`, `control-ui`, and `control-cli` from `cursor-team-kit`. Claude Code and Grok both read that folder. A same-named skill of yours would shadow pstack's, so the install stops and names it.
- Links the `poteto-agent` and `comment-sicko` agents into `~/.claude/agents/` and `~/.grok/agents/`.
- Writes `~/.config/pstack/models.md` with the default role models, if the file does not exist.
- Adds a short rules block to `~/.claude/CLAUDE.md` and `~/.grok/AGENTS.md`: no AI attribution, the git and test skills by path, and no frontend tests unless asked. These apply even outside `/poteto-mode`. A repository's own instruction files win, except on attribution.
- Sets `"attribution": { "commit": "", "pr": "" }` in `~/.claude/settings.json`, so Claude Code adds no co-author trailer.

`--dry-run` prints the plan. `--uninstall` removes the links and the rules block.

## Use

Start each task with `/poteto-mode`, the goal, and how to tell it is done.

```
/poteto-mode group windows show stale HP when someone else damages a selected target. fix it. done means a regression test that failed before the fix passes, and the PR body is ready.
```

**Start the thread on Claude.** The thread's model is the lead. It owns the design, the tests, and the review verdict, and hands the code to a delegate. The same discount-code task took these times with every check passing:

| Lead | Time | Use it for |
| --- | --- | --- |
| Sonnet 5.5 | 5.5 min | Everyday work. It wrote the simplest code. |
| Opus 5.5 | not measured | Hard design work, where judgment matters more than speed. |
| Grok 4.7 Fast or Grok 4.7 | 14 to 16 min | When you want Grok to lead. It hands the review verdict and the PR text to Claude. |

The mode picks a playbook. For a feature or a bug fix it now runs, in order:

1. **project-conventions.** Reads every `AGENTS.md` and `CLAUDE.md` on the path, the lint and CI config, and nearby code. Returns the rules and the exact commands.
2. **reuse-scan.** Searches the codebase four ways for code that already does the job. Returns a reuse brief that every code delegate must follow.
3. **tdd.** For backend behavior, writes the tests from the requirement and commits them red. The implementer turns them green without touching them, and `red-green.sh` proves it from git history. Frontend code gets no tests.
4. **interrogate.** Before every PR, reviewers try to break the diff, at least one of them from a model family that did not write it.
5. **git-conventions.** Conventional Commits, a PR body with only Why, Testing, and Deployment, and `check-message.sh` on every message.

## Update from upstream

```bash
scripts/sync-upstream.sh
```

It merges `upstream/main`, rebuilds the generated tree with this fork's generator, and runs every script test. On a real conflict, or when the generator rejects an upstream change, it stops with the merge still open. Fix the cause, stage it, and run `scripts/sync-upstream.sh --continue`. It also says when to rerun the install, because skills came or went, and when upstream changed its Claude Code adapter, which you port into the fork's own adapter.

## Models

`~/.config/pstack/models.md` holds one line per role in Cursor's slug form, such as `grok-4.7-xhigh-fast` or `claude-opus-5-5-xhigh`. `/setup-pstack` rewrites it. Opus does design synthesis, review judgment, and prose, as upstream has it. The install departs from upstream on who writes code:

- **Sonnet writes everyday code**, through the `feature, refactoring`, `bug-fix`, and `perf-issue` lines. In an eval it wrote the same code as Grok in a third of the time.
- **Opus writes the hardest changes**, through the `hardest tasks` line.
- **Grok writes code where volume pays**: bulk edits across many files, parallel attempts through the `swarm workers` and `hillclimb` lines, and the second design in `architect` and `arena`. That load stays off your Claude limits.

Its `# speed` line decides whether the `-fast` slugs stay fast. `fast`, the install default, keeps them fast on every spawn, so run times stay steady. A fast Grok seat finished about twice as fast in an eval and costs about twice as much per token. `standard` follows upstream and uses fast mode only for urgent jobs.

`interrogate reviewers` is Opus and Sonnet instead of Opus and Grok. In an eval on a diff with three planted issues, Opus and Sonnet reviews took one to two and a half minutes and Grok reviews took six to twelve, and the Grok reviews caught nothing the Claude ones missed. A small change keeps that panel. For a larger change, the **Opening a PR** playbook adds a reviewer from the family that did not write most of the code, which is Grok when Claude wrote it.

How a role reaches its model depends on where the parent runs.

| Parent | Claude roles | Grok roles |
| --- | --- | --- |
| Claude Code in T3 | Native `Agent` tool | T3 `delegate_task` |
| Grok in T3 | T3 `delegate_task` | T3 `delegate_task`, because `spawn_subagent` cannot set the effort |
| Claude Code alone | Native `Agent` tool | `grok` headless for read-only seats, else the session model |
| Grok alone | `claude -p` headless for read-only seats, else the session model | Native `spawn_subagent` at the session's effort |

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

- `skills/pstack-harness/` maps Cursor names to Claude Code, Grok, and T3 Code. Its Claude Code adapter starts from upstream's `docs/harness/claude-code.md`, which stays in place so upstream edits to it still merge.
- `skills/git-conventions/`, `skills/project-conventions/`, and `skills/reuse-scan/`.
- `skills/git-conventions/scripts/check-message.sh` and `skills/tdd/scripts/red-green.sh`, with tests.
- `../scripts/install-portable-pstack.sh` and `../scripts/sync-upstream.sh`, with tests.

Edited upstream files:

- `skills/tdd/SKILL.md` is rewritten: backend changes are test-first by default, and frontend code gets no tests. Upstream rarely changes this file.
- `skills/poteto-mode/SKILL.md` adds four triggers (project conventions and reuse, TDD, git, and the small-change lane), sends bulk code to the `swarm workers` model, and allows a short comment on genuinely complex code.
- `playbooks/feature.md`, `bug-fix.md`, and `refactoring.md` fold those steps into their existing steps and let a small change skip `how` and `architect`. `opening-a-pr.md` points its description format at `git-conventions` and adds the cross-family review.
- `agents/comment-sicko.md` and `skills/no-comments/SKILL.md` keep tool-read annotations and the short orientation comment.
- `agents/poteto-agent.md`, `skills/poteto-help/SKILL.md`, `skills/interrogate/references/code-quality-review.md`, and the skill table in `README.md` get a few lines each.
- `../scripts/generate-pstack-harness-trees.mjs` points every generated skill at the harness skill, ships the `cursor-team-kit` companions, and checks each adapter on its own.

## Limits

- A Grok session started by `spawn_subagent` cannot spawn its own subagents, so its parent runs the review panels. A Grok thread that T3 started can spawn.
- Grok's native `spawn_subagent` cannot set the effort, so outside T3 a Grok seat runs at the session's effort.
- Bugbot, Cursor cloud agents, Cursor Automations, and Custom Modes have no equivalent. The harness skill maps each to the nearest substitute or skips it. The `benny` automation pack stays Cursor-only.
