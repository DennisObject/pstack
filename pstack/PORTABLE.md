# Portable pstack

This fork runs [pstack](./README.md) in Claude Code, including Claude Code threads in T3 Code, with the same playbooks and skills it uses in Cursor. It also adds house rules for git, testing, reuse, and comments. The upstream skills stay as poteto wrote them, apart from a few short edits listed at the end, so upstream updates merge cleanly.

## Install

```bash
git clone <this fork> ~/Projects/pstack
~/Projects/pstack/scripts/install-portable-pstack.sh
```

The script is safe to rerun and never replaces a skill or agent you own. It does five things:

- Links every skill of the generated tree into `~/.claude/skills/`. The tree also carries `deslop`, `control-ui`, and `control-cli` from `cursor-team-kit`. A same-named skill of yours would shadow pstack's, so the install stops and names it.
- Links the `poteto-agent` and `comment-sicko` agents into `~/.claude/agents/`.
- Writes `~/.config/pstack/models.md` with the default role models, if the file does not exist.
- Adds a short rules block to `~/.claude/CLAUDE.md`: no AI attribution, the git and test skills by path, and no frontend tests unless asked. These apply even outside `/poteto-mode`. A repository's own instruction files win, except on attribution.
- Sets `"attribution": { "commit": "", "pr": "" }` in `~/.claude/settings.json`, so Claude Code adds no co-author trailer.

`--dry-run` prints the plan. `--uninstall` removes the links and the rules block.

## Use

Start each task with `/poteto-mode`, the goal, and how to tell it is done.

```
/poteto-mode group windows show stale HP when someone else damages a selected target. fix it. done means a regression test that failed before the fix passes, and the PR body is ready.
```

Start the chat on Sonnet for everyday work and on Opus for hard design. The chat's model leads: it owns the design, the tests, and the review verdict, and hands the code to a delegate. A Sonnet lead finished the eval task in 5.5 minutes with every check passing.

The mode picks a playbook. For a feature or a bug fix it now runs, in order:

1. **project-conventions.** Reads every `AGENTS.md` and `CLAUDE.md` on the path, the lint and CI config, and nearby code. Returns the rules and the exact commands.
2. **reuse-scan.** Searches the codebase four ways for code that already does the job. Returns a reuse brief that every code delegate must follow.
3. **tdd.** For backend behavior, writes the tests from the requirement and commits them red. The implementer turns them green without touching them, and `red-green.sh` proves it from git history. Frontend code gets no tests.
4. **interrogate.** Before every PR, Opus and Sonnet reviewers try to break the diff.
5. **git-conventions.** Conventional Commits, a PR body with only Why, Testing, and Deployment, and `check-message.sh` on every message.

## Update from upstream

```bash
scripts/sync-upstream.sh
```

It merges `upstream/main`, rebuilds the generated tree with this fork's generator, and runs every script test. On a real conflict, or when the generator rejects an upstream change, it stops with the merge still open. Fix the cause, stage it, and run `scripts/sync-upstream.sh --continue`. It also says when to rerun the install, because skills came or went, and when upstream changed its Claude Code adapter, which you port into the fork's own adapter.

## Models

`~/.config/pstack/models.md` holds one line per role in Cursor's slug form, such as `claude-opus-5-5-xhigh`. `/setup-pstack` rewrites it. Every role runs on Claude: Opus for judgment, design, prose, and the hardest changes, and Sonnet for code, exploration, and parallel workers. Panels such as `architect` and `interrogate` pair Opus with Sonnet, except that a small change gets one Sonnet reviewer.

Every role starts at `high` effort, the `medium` budget in `/setup-pstack`. Upstream starts at `xhigh`, which is built for unlimited tokens. In our evals an Opus reviewer at `xhigh` used twice the output tokens of one at `high` and found the same issues. Most of a run's usage is thinking and output tokens, plus about 25k tokens to start each subagent. Re-reading the context is cheap, because Claude caches it. So the savings come from lower effort and fewer seats, not shorter skills.

Upstream gives Grok the code and exploration seats. This fork does not, because Grok and GPT added nothing in our evals. On the same diffs, Grok and GPT-6.1-sol reviews found no issue that the Opus and Sonnet reviews missed, and Grok was slower at every seat. Upstream skills still name Grok slugs as defaults, and the harness runs those on Sonnet.

## Project rules belong in AGENTS.md

pstack carries the workflow. Each repository's `AGENTS.md` carries the facts: commands, architecture rules, and style, such as "PSR-12, enforced by `composer lint`". Keep these points in mind:

- Claude Code loads `AGENTS.md` only in a directory without its own `CLAUDE.md`. Make each `CLAUDE.md` a single line, `@AGENTS.md`, or delete it.
- Keep the file short, and link to longer references.
- Put a rule a tool can enforce into the tool's config, and name the command in `AGENTS.md`.
- Drop workflow rules that pstack now covers, such as test-first, comments, and git, unless the project needs a different rule. A project rule beats a pstack default.

[`project-conventions/references/agents-md-template.md`](./skills/project-conventions/references/agents-md-template.md) has a template.

## What differs from upstream

New files:

- `skills/pstack-harness/` maps Cursor names to Claude Code and T3 Code. Its Claude Code adapter starts from upstream's `docs/harness/claude-code.md`, which stays in place so upstream edits to it still merge.
- `skills/git-conventions/`, `skills/project-conventions/`, and `skills/reuse-scan/`.
- `skills/git-conventions/scripts/check-message.sh` and `skills/tdd/scripts/red-green.sh`, with tests.
- `../scripts/install-portable-pstack.sh` and `../scripts/sync-upstream.sh`, with tests.

Edited upstream files:

- `skills/tdd/SKILL.md` is rewritten: backend changes are test-first by default, and frontend code gets no tests. Upstream rarely changes this file.
- `skills/poteto-mode/SKILL.md` adds four triggers (project conventions and reuse, TDD, git, and the small-change lane) and allows a short comment on genuinely complex code.
- `playbooks/feature.md`, `bug-fix.md`, and `refactoring.md` fold those steps into their existing steps and let a small change skip `how` and `architect`. `opening-a-pr.md` points its description format at `git-conventions` and runs `interrogate` before every PR.
- `agents/comment-sicko.md` and `skills/no-comments/SKILL.md` keep tool-read annotations and the short orientation comment.
- `agents/poteto-agent.md`, `skills/poteto-help/SKILL.md`, `skills/interrogate/references/code-quality-review.md`, and the skill table in `README.md` get a few lines each.
- `../scripts/generate-pstack-harness-trees.mjs` points every generated skill at the harness skill, ships the `cursor-team-kit` companions, and checks that the Claude Code adapter maps every Cursor name.

## Limits

- Bugbot, Cursor cloud agents, Cursor Automations, and Custom Modes have no equivalent. The harness skill maps each to the nearest substitute or skips it. The `benny` automation pack stays Cursor-only.
