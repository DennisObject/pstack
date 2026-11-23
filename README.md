# pstack

A fork of [poteto's pstack](https://github.com/cursor/plugins/tree/main/pstack) for Claude Code, Codex, and Grok. It adds house rules for git, tests, reuse, and comments. It does not target Cursor.

## Install

```bash
git clone https://github.com/DennisObject/pstack.git ~/Projects/pstack
~/Projects/pstack/scripts/install-portable-pstack.sh
```

The script links every skill into `~/.claude/skills/` and the agents into `~/.claude/agents/`. It is safe to rerun. `--dry-run` prints the plan and `--uninstall` removes the links. [`pstack/PORTABLE.md`](pstack/PORTABLE.md) lists everything it does.

Codex and Grok read the same skills. Link each `~/.agents/skills/<name>` to `harness/pstack/claude-code/skills/<name>`.

## Use

Start each task with `/poteto-mode`, the goal, and how to tell it is done.

```
/poteto-mode fix the stale HP in group windows. done means a regression test that failed before the fix passes.
```

[`pstack/README.md`](pstack/README.md) lists the playbooks, skills, and principles.

## Change a skill

1. Edit the source in `pstack/skills/` or `pstack/agents/`.
2. Run `node scripts/generate-pstack-harness-trees.mjs`. It rebuilds `harness/pstack/claude-code/`, which the installed links point to.
3. Commit the source and the generated files together.

Never edit `harness/pstack/` by hand.

## Update from upstream

```bash
scripts/sync-upstream.sh
```

It merges upstream, rebuilds the generated tree, and runs the script tests. On a conflict it stops. Resolve the files, stage them, and run `scripts/sync-upstream.sh --continue`. For `README.md` and `pstack/README.md`, keep this fork's version.

## Layout

| Path | What it holds |
| --- | --- |
| `pstack/skills/`, `pstack/agents/` | Skill and agent sources. |
| `harness/pstack/claude-code/` | The generated tree that the install links to. |
| `pstack/skills/pstack-harness/` | Maps the tool and model names in the skills to Claude Code, Codex, and Grok. |
| `cursor-team-kit/skills/` | Source of `deslop`, `control-ui`, and `control-cli`, which the generated tree copies. |
| `scripts/` | Install, generator, and upstream sync scripts, with tests. |

The other folders come from upstream. This fork does not use them.

## License

MIT
