# pstack inside T3 Code

T3 Code runs Claude Code as threads and adds a `t3-code` MCP server. Read this file after [claude-code.md](claude-code.md). Everything else still comes from there.

- **Subagents.** Spawn every pstack seat with Claude Code's `Agent` tool. Never use `delegate_task`, `t3_thread_launch`, or `create_threads` for a pstack seat. They open separate threads that only the user asks for.
- **Cursor's `/loop`.** A finished subagent wakes you, so end your turn instead of polling. For a timer, use `schedule_task` with `{ "type": "interval", "everyMs": <ms> }`.
- **Cursor Automations.** Use `schedule_task`, with `{ "type": "webhook" }` for a webhook trigger.
- **After you open a PR.** When the session offers `link_pull_request`, call it with the PR URL right after `gh pr create`, for every PR in a stack.
