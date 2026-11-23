# pstack harness tree

This folder is generated from `pstack/skills`, `pstack/agents`, `pstack/LICENSE`, and `pstack/plugin.json`. Do not edit it by hand.

Claude Code and Codex use `claude-code/`. `scripts/install-portable-pstack.sh` installs it. The tree also carries `deslop`, `control-ui`, `control-cli` from `cursor-team-kit/skills`. It leaves out `pstack/docs` and `pstack/README.md`. A relative link to a pstack file that the tree leaves out points at that file on GitHub `main` instead.

After editing those sources, run `node scripts/generate-pstack-harness-trees.mjs` from the repository root and commit the result.
