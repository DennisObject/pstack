# Portable pstack

This fork runs [pstack](./README.md) in Claude Code (including Claude Code threads in T3 Code), Codex, and Grok. It adds house rules for git, tests, code reuse, and comments. Upstream skills stay close to how poteto wrote them, apart from the short edits listed below, so upstream updates merge cleanly.

## What the install does

See [the repository README](../README.md#install) for the install commands.

`scripts/install-portable-pstack.sh` is safe to rerun and never replaces a skill or agent you own. It does five things:

- Links every skill from `harness/pstack/claude-code/skills/` into `~/.claude/skills/`. That tree includes `deslop`, `control-ui`, and `control-cli` from `cursor-team-kit/`. If you already own a skill with the same name, your skill would shadow pstack's, so the install stops and names it.
- Links the `poteto-agent` and `comment-sicko` agents into `~/.claude/agents/`.
- Writes `~/.config/pstack/models.md` with the default role models if the file does not exist.
- Adds a short rules block to `~/.claude/CLAUDE.md` that forbids AI attribution, points to the git and test skills by path, and forbids frontend tests unless asked. These rules apply even outside `/poteto-mode`. A repository's own instruction files win, except on attribution.
- Sets `"attribution": { "commit": "", "pr": "" }` in `~/.claude/settings.json` so Claude Code adds no co-author trailer.

`--dry-run` prints the plan without making changes. `--uninstall` removes the links and the rules block, and keeps `~/.config/pstack/models.md` and the attribution setting.

Grok also reads `~/.claude/skills/`, so the install covers it. Codex reads skills from `~/.agents/skills/`, so link each `~/.agents/skills/<name>` to `harness/pstack/claude-code/skills/<name>`.

## Use

Start each task with `/poteto-mode`, the goal, and how to tell when it is done:

```
/poteto-mode Group windows show stale HP when someone else damages a selected target. Fix it. Done means a regression test that failed before the fix now passes, and the PR body is ready.
```

Start the chat on Sonnet for everyday work and on Opus for hard design. The chat's model leads the task. It owns the design, the tests, and the review verdict, and hands code writing to a delegate. A Sonnet lead finished the eval task in 5.5 minutes with every check passing.

`/poteto-mode` picks a playbook. For a feature or a bug fix, it runs these skills in order:

1. **project-conventions.** Reads every `AGENTS.md` and `CLAUDE.md` on the path, the lint and CI configs, and nearby code. Returns the rules and exact commands.
2. **reuse-scan.** Searches the codebase five ways (by precedent, by name, by shape, by neighbor, and by behavior) for code that already does the job. Returns a reuse brief that every code delegate must follow.
3. **tdd.** Writes tests for backend behavior from the requirement and commits them red. The implementer turns them green without editing them, and `red-green.sh` proves the cycle from git history. Frontend code gets no tests unless asked.
4. **interrogate.** Runs before every PR so reviewer models try to break the diff. It picks one Sonnet reviewer for a small or ordinary change, one Opus reviewer for a subtle or high-risk change, or both for a contested design or when asked.
5. **git-conventions.** Enforces Conventional Commits, a PR body with only `Why`, `Testing`, and `Deployment`, no AI attribution, and `check-message.sh` on every message.

## Update from upstream

Run `scripts/sync-upstream.sh` from the repository root (see [the repository README](../README.md#update-from-upstream)).

The script merges `upstream/main`, rebuilds `harness/pstack/claude-code/` with this fork's generator, checks that the tree is up to date, and runs every script test under `scripts/` and `pstack/skills/*/scripts/`. If a conflict occurs, or if the generator rejects an upstream change, the script stops with the merge still open. Fix the cause, stage the files, and run `scripts/sync-upstream.sh --continue`. Keep this fork's version of `README.md` and `pstack/README.md` on conflict.

After the merge, the script tells you when to rerun `scripts/install-portable-pstack.sh` because skills were added or removed. It also tells you when upstream changed `pstack/docs/harness/`, so you can port relevant edits into `pstack/skills/pstack-harness/references/claude-code.md`.

## Models

`~/.config/pstack/models.md` holds one line per role as a model slug, such as `claude-opus-5-5-high`. `/setup-pstack` rewrites it. Claude and GPT never go above `high`. A slug or budget that says `xhigh` or `max` for those families is written and spawned as `high`. Grok may use `xhigh`.

In a Claude session, every role runs on Claude. Opus handles judgment, design, prose, and the hardest changes. Sonnet handles code, git history, and parallel workers. Haiku handles the `how` explorers. `architect` pairs Opus with Sonnet. `interrogate` picks reviewers by size and risk. It runs one Sonnet reviewer for a small or ordinary change, one Opus reviewer for a subtle or high-risk change, and both only for a contested design or when asked.

Haiku got the explorer seat from a blind eval on a 700-file PHP API and its Vue frontend. On "how does X work" questions, Haiku explorers covered as many verified facts as Sonnet explorers at a third to a tenth of the cost, but took about twice as long. Haiku fell behind on git history and on reuse decisions, so `why` investigators stay on Sonnet and the lead makes every reuse decision.

Every role starts at `high` effort, which is the `medium` budget in `/setup-pstack`. Upstream starts at `xhigh`, which assumes unlimited tokens. In our evals, an Opus reviewer at `xhigh` used twice the output tokens of one at `high` and found the same issues. Most of a run's usage is thinking and output tokens, plus about 25k tokens to start each subagent. Re-reading context is cheap because Claude caches it. Savings come from lower effort and fewer seats, not shorter skills.

Upstream gives Grok the code and exploration seats. This fork does not, because Grok and GPT added nothing in our evals. On the same diffs, Grok and GPT-6.1-sol reviews found no issue that the Opus and Sonnet reviews missed, and Grok was slower at every seat. Upstream skills still name Grok slugs as defaults, and the harness runs those on Sonnet.

## Project rules belong in AGENTS.md

pstack carries the workflow. Each repository's `AGENTS.md` carries the project facts, such as commands, architecture rules, and code style (for example, "PSR-12, enforced by `composer lint`"). Keep these points in mind:

- Claude Code loads `AGENTS.md` only in a directory without its own `CLAUDE.md`. Make each `CLAUDE.md` a single line (`@AGENTS.md`), or delete it.
- Keep `AGENTS.md` short, and link to longer references.
- Put any rule a tool can enforce into that tool's config, and name the command in `AGENTS.md`.
- Drop workflow rules that pstack already covers, such as test-first, comments, and git, unless the project needs a different rule. A project rule beats a pstack default.

See [`skills/project-conventions/references/agents-md-template.md`](./skills/project-conventions/references/agents-md-template.md) for a template.

## What differs from upstream

New files:

- `skills/pstack-harness/` maps the tool and model names that upstream skills use to Claude Code, T3 Code, Codex, and Grok. Its Claude Code adapter starts from upstream's `docs/harness/claude-code.md`, which stays in place so upstream edits to it still merge.
- `skills/git-conventions/`, `skills/project-conventions/`, and `skills/reuse-scan/`.
- `skills/git-conventions/scripts/check-message.sh` and `skills/tdd/scripts/red-green.sh`, with tests.
- `../scripts/install-portable-pstack.sh` and `../scripts/sync-upstream.sh`, with tests.

Edited upstream files:

- `skills/tdd/SKILL.md` is rewritten so backend changes are test-first by default, tests cover only what the change adds, and frontend code gets no tests unless asked. Upstream rarely changes this file.
- `skills/poteto-mode/SKILL.md` adds triggers for project conventions and reuse, TDD, git, the small-change lane, and pre-commit comment checks. It defaults to no comments and allows only a non-obvious why or a short orientation comment (at most two short sentences) on complex code.
- `skills/poteto-mode/playbooks/feature.md`, `bug-fix.md`, and `refactoring.md` fold those steps into their existing steps and let a small change skip `how` and `architect`. `skills/poteto-mode/playbooks/opening-a-pr.md` points its description format at `git-conventions` and runs `interrogate` before every PR.
- `agents/comment-sicko.md` and `skills/no-comments/SKILL.md` keep tool-read annotations and the short orientation comment.
- `agents/poteto-agent.md`, `skills/poteto-help/SKILL.md`, `skills/interrogate/references/code-quality-review.md`, and the skill table in `README.md` get a few lines each.
- `../scripts/generate-pstack-harness-trees.mjs` points every generated skill at the harness skill, copies the `cursor-team-kit/` companions, and checks that every adapter maps every tool name the skills use.

## Limits

- Some upstream skills mention features that exist only in Cursor, such as Bugbot, cloud agents, Automations, and Custom Modes. The harness skill maps each feature to the nearest substitute or skips it. This fork does not use the `benny` automation pack.
