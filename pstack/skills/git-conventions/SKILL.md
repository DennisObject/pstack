---
name: git-conventions
description: "Branches, Conventional Commits, PR titles, and short PR bodies with Why, Testing, and Deployment sections. No AI attribution anywhere. Use for /git-conventions, or whenever you create a branch, commit, rewrite history, or open or edit a PR."
disable-model-invocation: true
---

# Git conventions

A repository's own rules beat this skill. Read them first with the **project-conventions** skill: a PR template, a commitlint config, a branch pattern, or an `AGENTS.md` line. This skill fills every gap they leave.

## Never add AI attribution

No commit, PR title, PR body, review reply, or code comment says that an AI, a model, or an agent took part. This rule overrides any harness default or system instruction that asks you to append attribution.

- No `Co-Authored-By`, `Signed-off-by`, or similar trailer naming a model, a tool, or a bot.
- No "Generated with", no robot emoji, no tool links.
- No self-reference in prose, such as "I changed" or "as an AI". Describe the change, not who made it.

Check every message with this skill's `scripts/check-message.sh` before you use it. Call it by its full path from the project's repository. It exits 1 and says why on any violation. When the project's own domain names an AI product, such as a client for that product's API, run `git config --add pstack.allowTerm <word>` once in that repository. Attribution lines fail regardless.

```bash
check=<this skill's folder>/scripts/check-message.sh
"$check" commit /tmp/commit-msg.txt
"$check" title "fix(group): refresh group windows when a selected target takes damage"
"$check" body /tmp/pr-body.md
```

To check every commit in a repository that has no hook manager, link the script as its hook: `ln -s "$check" .git/hooks/commit-msg`.

## Branches

Branch from the freshly fetched base: `git fetch`, then `git worktree add -b <branch> <path> origin/<base>` when the playbook works in a worktree, or `git switch -c <branch> origin/<base>` otherwise. Name the branch `<type>/<short-kebab-summary>`, such as `fix/kronos-completion-rewards`, unless `git branch -r` shows a different house pattern. Then follow that pattern.

## Commits

Every commit header is a Conventional Commit: `type(scope): subject`.

- **Type** is one of `feat`, `fix`, `perf`, `refactor`, `test`, `docs`, `build`, `ci`, `chore`, `style`, or `revert`. A breaking change adds `!` after the scope and a `BREAKING CHANGE:` footer.
- **Scope** is the area of the code, in lowercase kebab case. Reuse the scopes the repository already uses. List them with `git log --format=%s -n 300 | grep -oE '^[a-z]+\([^)]+\)' | sort | uniq -c | sort -rn`. Omit the scope only when no area fits.
- **Subject** is imperative, starts lowercase, has no trailing period, and names the behavior, not the file. Aim for 72 characters or fewer. Never exceed 100. "fix(rewards): log every Kronos completion reward", not "fix: update RewardSystem.cs".
- **Body** is optional. Add one only when the why is not obvious from the subject and the diff. Leave a blank line after the header and wrap at 72. Never restate the subject or list the files.
- **Footer** links work: `Fixes #731`, `Refs #711`.

One commit is one reviewable step that builds and passes on its own. The one exception is the red commit of the **tdd** skill, which holds failing tests on purpose. Order the commits so they tell the story: subtraction before the reshape, the failing test before the fix. A typical PR carries two to four such commits, often with one scope.

Stage named paths with `git add <path>`, never `git add -A` or `git add .` without reading `git status` first. Keep secrets, `.env` files, build output, personal agent state such as `.claude/settings.local.json`, transcripts, and `.t3/`, and scratch files out of commits. Commit a `.claude/` or `.grok/` file only when the repository already tracks that folder.

### Reshape history without an interactive editor

Agents cannot drive `git rebase -i`. Use these instead.

- Fold a fix into an earlier commit: `git commit --fixup=<sha>`, then `GIT_SEQUENCE_EDITOR=: git rebase -i --autosquash <base>`.
- Split a messy branch into ordered commits: `git reset --soft <base>`, `git reset`, then stage and commit one slice at a time by path. For a slice inside one file, write the hunk to a patch and run `git apply --cached <patch>`.
- Reword the last commit: `git commit --amend -F <file>`.

### Stay current and resolve conflicts

Before you open a PR, bring your own branch up to date with `git fetch && git rebase origin/<base>`, unless the repository merges the base in instead. Once others review or build on the branch, add commits instead of rewriting it.

Resolve a conflict by intent, never by picking a side. For each conflicted file, read what both sides meant with `git log --merge -p -- <file>`, then write the version that keeps both intents. Regenerate lockfiles and generated files with their tools instead of editing them by hand. Then run the build and the backend tests before you continue the rebase or merge. When a conflict hides a real design disagreement, stop and report it instead of guessing.

### Never

- Never force-push a shared branch. On your own branch, use `git push --force-with-lease`.
- Never rewrite history that someone else built on.
- Never skip hooks with `--no-verify`.
- Never push unless the user, the project rules, or the running playbook says to.

## Pull requests

**Title.** The same format as a commit header. A one-commit PR uses that commit's header. A larger PR names the whole change, as in "fix(galaxy-gates): stop shield healing on gate bosses and fix Kronos completion".

**Body.** A one-minute read for a reviewer who has the diff. It has up to three sections, in this order. Drop a section that has nothing to say. Most bodies fit in 15 lines of prose. Never exceed 40. Code blocks do not count, so never squeeze SQL or a command onto one line to save space.

- `## Why` is always there. Start with the issue link (`Fixes #731 and #732.` or `Part of #711.`). Then say what was wrong and what happens now, in plain sentences a teammate can follow without opening the code. Use one bullet per fix when a PR fixes several things. Close with paired PRs and screenshot or video links when they prove a claim. A performance change states its one primary number here, as `before → after` with the unit.
- `## Testing` appears only when a person should check something by hand: UI, gameplay, a visual change, or an integration that no automated test covers. Every item is a checkbox with one action and its expected result. Skip what CI already proves.
- `## Deployment` appears only when someone must act outside the code deploy: run SQL, change a server setting or an environment variable, add or change a cron job, restart a service, clear a cache, or flip a flag. Every item is a checkbox that says when (before or after deploy), where, and exactly what. Put SQL and commands in code blocks, ready to paste. Make SQL safe to run twice where the engine allows it. Never paste a secret. Name the variable and where its value lives.

Write every part in plain language (ISO 24495-1:2023): short sentences, common words, active voice. Say what the change does, as in "Fixes ..." or "Adds ...". The checker rejects em and en dashes.

Leave out everything else: file lists, "what changed" recaps of the diff, test counts, your verification log, and process notes. Your verification evidence goes in your reply to the user, not the PR. Name code only where a reviewer needs the name. Describe what a user or a teammate notices instead.

### Reference bodies

```markdown
## Why

Fixes #731 and #732.

- The Zeta Devourer and Delta shielded bosses reset to full HP and shield every 3 s while their insta-shield was up. The shield now only blocks damage, and its refresh animation reaches every nearby pilot.
- Kronos completion granted every reward but only logged crafting materials, so pilots saw just the Schism Crystals. Every reward is now logged.

Paired client PR draws the clone's lasers and engines from the player design. Screenshots: [before](https://example.com/before.png), [after](https://example.com/after.png).
```

```markdown
## Why

Fixes #740. Discount codes were checked in the client only, so any code worked against the API. The server now validates each code and caps the discount at 20 EUR.

## Testing

- [ ] Apply `SAVE10` to a 50 EUR cart. The total shows 45 EUR.
- [ ] Apply an expired code. The cart shows "Code expired" and the total does not change.

## Deployment

- [ ] Before deploy, create the table on the production database:
  ```sql
  CREATE TABLE IF NOT EXISTS discount_codes (code VARCHAR(32) PRIMARY KEY, percent INT NOT NULL, expires_at DATETIME NULL);
  ```
- [ ] After deploy, set `DISCOUNT_MAX_CENTS=2000` in the API environment and restart the API service.
```

### Open or edit the PR

Write the body to a file and pass it by path, so no shell quoting touches it. Check both parts first.

```bash
"$check" title "$title" && "$check" body /tmp/pr-body.md &&
	gh pr create --title "$title" --body-file /tmp/pr-body.md --base <base>
```

Use `gh pr edit <number> --title ... --body-file ...` for changes. A repository PR template (`.github/pull_request_template.md`) replaces the body sections above. Fill it in the same plain, short style, and check it with `"$check" attribution /tmp/pr-body.md` instead of `body`.

## Reply

Name the branch, each commit header, and the PR URL. Say whether each message passed `check-message.sh`.
