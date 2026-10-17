---
name: project-conventions
description: "Read a repository's own rules before writing code: every AGENTS.md and CLAUDE.md on the path, lint and format configs, CI, and the code next to the change. Returns a short project brief with the rules and commands that apply. Use for /project-conventions, or before any code change in a repository."
disable-model-invocation: true
---

# Project conventions

pstack holds no language rules. The repository does. A PHP project's `AGENTS.md` says PSR-12, a C# project's `.editorconfig` says how to name fields, and CI says what must pass. This skill finds those rules before you write code, so the change reads as if the team wrote it.

**Project rules beat pstack defaults. pstack defaults beat your habits.** When an instruction file conflicts with a pstack skill, follow the instruction file and say so in your reply. The deeper file wins over the shallower one.

## 1. Read every instruction file on the path

Your harness loads only some of these, so read them yourself. Walk from the repository root down to each directory the change will touch, and read in each:

- `AGENTS.md`, `Agents.md`, `AGENT.md`, `CLAUDE.md`, and `.claude/CLAUDE.md`.
- `.cursor/rules/*.mdc`, `.github/copilot-instructions.md`, and `CONTRIBUTING.md`.
- Any file those point to, such as a spec, a reference doc, or a nested `AGENTS.md`.

Flag drift in your reply. Two examples are an instruction file marked obsolete that a harness still loads, and two files that disagree. Claude Code loads `AGENTS.md` only where a directory has no `CLAUDE.md`, so a stale `CLAUDE.md` hides the real rules from it. The fix is a `CLAUDE.md` that holds one line, `@AGENTS.md`.

## 2. Find the commands that prove a change

The instruction files come first. Fill the gaps from what the repository runs:

- CI workflows, such as `.github/workflows/*.yml`. CI is the truth about what must pass.
- Manifests and task runners, such as `package.json` scripts, `composer.json` scripts, `Makefile`, `justfile`, `*.sln` and `*.csproj`, `build.gradle`, `pom.xml`, and `pyproject.toml`.
- Lint and format configs, such as `.editorconfig`, `phpcs.xml`, `pint.json`, `.php-cs-fixer.php`, `phpstan.neon`, `rector.php`, `eslint.config.*`, `.prettierrc*`, `Directory.Build.props`, and `.stylecop.json`.
- Git hooks and commit rules, such as `.husky/`, `.pre-commit-config.yaml`, `commitlint.config.*`, and `.github/pull_request_template.md`.

Record the exact commands for format, lint, type check, build, and backend tests. Prefer the narrowest form, such as one test file or one project, for the inner loop, and the CI form before you commit.

## 3. Learn the local style from the nearest code

Open two or three files of the same kind as the one you will write: the sibling controller, the neighboring service, the test next to the code. Note how they name things, handle errors, inject dependencies, split files, and structure tests. Copy the nearest good example. A rule the code follows everywhere is a rule, even when no file states it.

## 4. Mark the frontend boundary

The **tdd** skill tests backend behavior and leaves frontend code untested unless the user asks. Name which paths in this repository are frontend: components, views, templates, styles, client stores, and client-side helpers inside a frontend app or package. If an instruction file sets a different testing policy, it wins.

## Output

Write a project brief of at most 15 lines and pass it to every delegate that writes code:

- **Rules that apply**, each with the file it came from.
- **Commands** for format, lint, type check, build, and backend tests.
- **Patterns to copy**, as file paths.
- **Frontend paths**, and the testing policy if a file overrides the default.
- **Drift**, if you found any.

If the repository has no instruction file, say so and offer, once, to draft an `AGENTS.md` from [references/agents-md-template.md](references/agents-md-template.md) as its own change.
