### Opening a PR

Invoked at the end of every other playbook.

**Worktree.** Work from a git worktree off main. Subagents inherit it. Multiple `Task` calls on the same branch each get their own worktree, or `git fetch && git reset --hard origin/<branch>` between them. Dirty branch with unrelated work: patch out, fresh worktree, apply. Snarled worktree: reset from main, redo minimally.

**Commits.** Commit liberally. Rebase into small, ordered commits before opening PRs. Each commit is a future PR: landable, ordered to tell the story. Amend when the fix belongs in a just-made commit. New commit when separable. Commit bodies don't restate the subject. Branch names, headers, and history reshaping follow the **git-conventions** skill, and every message passes its `check-message.sh`.

**PRs.** Run `/deslop` from `cursor-team-kit` over the diff before commit and `/no-comments` before review. Write every PR title, description, and commit body with `/technical-writing` (every layer except Diátaxis, and apply the STE vocabulary rules: one word per action, keep articles, a plain verb over `-ing` where one works), then apply `/unslop`.

**Independent review.** Before the PR opens, run the **interrogate** skill on the diff, so at least one reviewer comes from a different model family than the one that wrote most of the code. Act on its Act On findings, or dismiss each with a concrete reason. Skip it only for a trivial diff, such as docs or a one-line change, and write `skip: <reason>`.

**Titles.** Conventional Commits `type(scope): subject`, no trailing period, per the **git-conventions** skill. Type such as `feat`, `fix`, `docs`, `refactor`, `test`, `chore`, or `perf`. Scope is an area the repository already uses. Subject is short, imperative, lowercase, and names the behavior, for example `fix(group): refresh group windows when a selected target takes damage`.

**Descriptions.** The PR body is a one-minute briefing, not a lab notebook, for a reviewer who has the diff. Write short, simple sentences with few identifiers, no walls of text. The body becomes the squash commit body, so keep it under 40 lines, and most fit in 15. The **git-conventions** skill owns the format. Use only these `##` headings, in this order, and drop a section with nothing to say:

- `## Why`: always. The issue link, then what was wrong and what happens now, one bullet per fix when there are several. Close with paired PRs and links to screenshots or videos that prove a claim. No SHAs, rebase genealogy, or "based on main" preamble.
- `## Testing`: only when a person should check something by hand. Checkbox items, each one action and its expected result.
- `## Deployment`: only when someone must act outside the code deploy, such as SQL, a server setting, an environment variable, or a cron job. Checkbox items that say when, where, and exactly what, with SQL and commands ready to paste.

Your verification evidence, perf numbers, swarm or arena recitals, full SHAs, and "CLEAN" verdicts go in your reply or a linked artifact, not the body. Run `check-message.sh` on the title and the body before you create the PR.

**Forge.** Resolve the forge before the first PR operation and keep that choice for create, edit, view, watch, and merge. GitHub CLI (`gh`) is the default. If `command -v origin` succeeds and Origin can resolve the repository, prefer `origin pr ...`. If Origin is absent or cannot resolve the repository, stay on `gh` and record the fallback. Do not require Graphite (`gt`).

**Built-in PR tool.** When the run provides a built-in PR tool, create, edit, retarget, and mark ready through it, never through a forge CLI. A CLI-made PR misses what the tool tracks. Use the resolved forge for everything the tool does not cover, and for every PR operation when the run has no such tool.

**Size and stacks.** Prefer five narrow PRs to one large PR. A stack is a base-branch chain. The root PR targets trunk. Each child branch rebases onto its parent's exact tip and its PR targets the parent branch. As a parent merges, move its child onto trunk per `playbooks/shipping.md` step 4. Without a built-in PR tool, per the resolved forge, create a child with `origin pr create --status open --base <parent-branch>` or `gh pr create --base <parent-branch>`, and retarget one with `origin pr edit <pr> --base <parent-branch>` or `gh pr edit <pr> --base <parent-branch>`. Branch from trunk only for independent work. Rebase on trunk before substantial stack work.

**Readiness.** Open every PR ready, never as a draft. A built-in PR tool can default to draft, so set `draft: false` on every creation call through it. With Origin, pass `--status open`. With `gh`, omit `--draft`. If a PR still opens as a draft, mark it ready through the PR tool, or run `origin pr ready <number>` or `gh pr ready <number>` according to the resolved forge. Run `origin pr view <number>` or `gh pr view <number>` before you refer to PR status.

**Babysit.** Opening a PR does not start a babysit. Post the URL and keep building. Finish the phase or stack first. Run a separate babysit pass only when the user asks for one after the whole stack exists. A babysit for each new PR stalls the build and spends checks on commits later waves restart. Push back when feedback drifts from intent.

A subagent that opens a PR runs `interrogate`, `/deslop`, and `/no-comments`, and posts the URL. It returns to the parent without babysitting, unless it is an Autopilot-full or Autopilot-stack owner. That owner's brief assigns the babysit loop and is the ask `playbooks/babysit.md` waits for. The owner starts the loop after its code-ready report, reports merge-ready or STACK-READY per its playbook, and is exempt from the rules here and in `playbooks/babysit.md` that hold babysitting until a whole stack is built.
