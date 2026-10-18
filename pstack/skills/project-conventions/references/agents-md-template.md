# AGENTS.md template

An `AGENTS.md` holds the facts about one repository that an agent cannot infer quickly: commands, architecture rules, and the conventions the code follows. pstack holds the workflow, such as test-first, reuse, comments, and git. Keep workflow rules out of `AGENTS.md` unless this project needs a different one.

Keep the file short, because every agent reads all of it on every task. Point to longer references instead of pasting them. Put a rule that a tool can enforce in the tool's config, and name the command here.

For Claude Code, make `CLAUDE.md` a single line, `@AGENTS.md`, or delete it. Claude Code skips `AGENTS.md` in a directory that has its own `CLAUDE.md`.

```markdown
# <Project name>

<One or two sentences: what this repository is, and what it owns.>

## Commands

- Format: `<command>`
- Lint: `<command>`
- Type check: `<command>`
- Build: `<command>`
- Backend tests: `<command>`. One file: `<command> <path>`.

## Architecture

- <Where each kind of code lives, such as "handlers in Handlers/, one type per file".>
- <The boundaries that must hold, such as "the server is authoritative and validates every packet".>

## Conventions

- <The style standard and the tool that enforces it, such as "PSR-12, enforced by `composer lint`".>
- <Naming, error handling, and dependency injection rules the code follows.>
- <Patterns to copy, as file paths.>

## Testing

- <Framework, location, and the kind of test to prefer, such as "integration tests against an in-memory database, not mocks".>
- <Frontend paths, if the default policy of no frontend tests needs a different line here.>

## Deployment

- <What runs outside the code deploy, such as "schema changes are manual SQL on the production database, never ORM migrations".>
```
