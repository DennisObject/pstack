# pstack inside T3 Code

T3 Code runs Claude Code, Grok, and other providers as threads, and its `t3-code` MCP server lets one thread delegate work to a child on any provider. Read this file after your harness reference. It adds cross-provider spawning. Everything else still comes from your harness reference.

## Discover what you can spawn

Call `orchestrator_capabilities` once per session before the first cross-provider spawn. It lists each provider's `providerInstanceId`, its models, and each model's option ids. Use only what it lists. `/setup-pstack` also uses it to detect models.

## Turn a slug into a `delegate_task` target

| Slug | `target` |
| --- | --- |
| `claude-<family>-<version>-<effort>`, such as `claude-opus-5-5-xhigh` or `claude-fable-5-1-high` | `providerInstanceId: "claudeAgent"`, `model: "claude-<family>-<version>"`, `options: { "effort": "<effort>" }`. |
| A `claude-*` slug that ends in `-fast` | The same, plus `"fastMode": true` when the model lists that option. Otherwise drop `-fast`. |
| `grok-<version>-<effort>-fast`, such as `grok-4.7-xhigh-fast` | `providerInstanceId: "grok"`, `model: "grok-<version>-build-fast"`, `options: { "reasoningEffort": "<effort>" }`. |
| `grok-<version>-<effort>` | The same with `model: "grok-<version>"`. |
| An effort the model does not list, such as `max` on Grok | The highest effort it lists below that. Say so. |
| `auto` or `inherit-parent` | Omit `target`. The child inherits your provider and model. |

Prefer your harness's own subagent tool when it can set the slug's model and effort. It is faster and can isolate a worktree. Claude Code's `Agent` tool can. Grok's `spawn_subagent` cannot, so a Grok parent spawns every configured Grok role through `delegate_task` too, and keeps `spawn_subagent` for `auto`, `inherit-parent`, and work that needs its worktree isolation. Use `delegate_task` for every other family.

## Spawn a child

- Put the whole brief in `task`. A child sees none of your conversation, so every brief stands alone, which pstack requires anyway.
- Set `role` to match the seat: `implementation` for code delegates, `review` for `interrogate` reviewers and judges, `research` for `how` and `why` investigators, `design` for `architect` and `arena` runners, `test` for test authors.
- Give each spawn a `clientRequestId` that names the role and the round, such as `interrogate-r1-reviewer-b`. Reuse it only to retry that same spawn.
- Use `mode: "async"`, the default. A finished child wakes your thread with its result, so end your turn instead of polling. Call `task_status` only when you need a result before your turn can continue.
- A new round is a new `delegate_task` with the consolidated brief: the original task, every later directive, and the prior round's findings. This is pstack's fresh-subagent rule. Never continue a child by messaging its thread.
- Never use `t3_thread_launch` or `create_threads` for a pstack subagent. Those open top-level threads, which only the user asks for.

## Map the Cursor fields

| Cursor | T3 `delegate_task` |
| --- | --- |
| `readonly: true` | `role: "review"` or `"research"`, and "Do not edit files" in the brief. Check `git status` afterward. |
| `environment: "cloud"` | `delegate_task` has no isolation field, so the child works in your checkout. Give each parallel writer its own worktree: name the `git worktree add <path> -b <branch>` command and the path in its brief, and tell it to edit only there. Read-only seats can share your checkout. |
| `run_in_background: true` | `mode: "async"`. |
| `resume` | A new `delegate_task` with the earlier result pasted into the brief. |
| `file_attachments` | List the paths in the brief. |
| Cursor's `/loop` | A child's completion wakes you. For a timer, `schedule_task` with `{ "type": "interval", "everyMs": <ms> }`. |
| Cursor Automations | `schedule_task`. Use `{ "type": "webhook" }` for a webhook trigger. |

## After you open a PR

When the session offers `link_pull_request`, call it with the PR URL right after `gh pr create`, for every PR in a stack.
