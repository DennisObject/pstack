# pstack

This repository is a fork of [poteto's pstack](https://github.com/cursor/plugins/tree/main/pstack) for Claude Code (including T3 Code), Codex, and Grok. It adds house rules for git, tests, code reuse, and comments.

## Install

Clone the repository and run the install script:

```bash
git clone https://github.com/DennisObject/pstack.git ~/Projects/pstack
~/Projects/pstack/scripts/install-portable-pstack.sh
```

The install script links every skill into `~/.claude/skills/` and the agents into `~/.claude/agents/`. You can rerun it safely. Pass `--dry-run` to print the plan without making changes. Pass `--uninstall` to remove the links and the rules block. See [`pstack/PORTABLE.md`](pstack/PORTABLE.md) for everything the install does, model settings, and how this fork differs from upstream.

Grok also reads `~/.claude/skills/`, so the install covers it. Codex reads skills from `~/.agents/skills/`. Link each `~/.agents/skills/<name>` to `harness/pstack/claude-code/skills/<name>`.

## Use

Start each task with `/poteto-mode`, the goal, and how to tell when it is done:

```
/poteto-mode Fix the stale HP in group windows. Done means a regression test that failed before the fix now passes.
```

See [`pstack/README.md`](pstack/README.md) for the full catalog of playbooks, skills, and principles.

## Change a skill

1. Edit the source in `pstack/skills/` or `pstack/agents/`.
2. Run `node scripts/generate-pstack-harness-trees.mjs`. This rebuilds `harness/pstack/claude-code/`, which the installed links point to.
3. Commit the source files and the generated files together.

Never edit `harness/pstack/` by hand.

## Update from upstream

```bash
scripts/sync-upstream.sh
```

The script merges `upstream/main`, rebuilds the generated tree, and runs the script tests. If a conflict occurs, the script stops. Resolve the conflicted files, stage them, and run `scripts/sync-upstream.sh --continue`. Keep this fork's version of `README.md` and `pstack/README.md` on conflict.

## Layout

| Path | Contents |
| --- | --- |
| `pstack/skills/`, `pstack/agents/` | Skill and agent sources. |
| `harness/pstack/claude-code/` | Generated tree that the installed links point to. |
| `pstack/skills/pstack-harness/` | Adapter that maps tool and model names in the skills to Claude Code, Codex, and Grok. |
| `cursor-team-kit/skills/` | Source of `deslop`, `control-ui`, and `control-cli`, which the generator copies into the generated tree. |
| `scripts/` | Install, generator, and upstream sync scripts, with their tests. |

The other folders at the repository root come from upstream. This fork does not use them.

## License

MIT
