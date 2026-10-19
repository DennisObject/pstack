---
name: reuse-scan
description: "Search the codebase for code that already does what you are about to write, then reuse it, extend it, or justify new code in one line. Returns a reuse brief for delegates. Use for /reuse-scan, before writing any new function, class, component, endpoint, query, or helper, and when reviewing a diff for duplication."
disable-model-invocation: true
---

# Reuse scan

Outside Cursor, read [the pstack harness skill](../pstack-harness/SKILL.md) once per session before you follow this skill. It maps the Cursor names in pstack skills to Claude Code, Codex, and Grok.

Every line you add is a line a teammate maintains by hand. Before you write something, show that the codebase does not already have it. Code that already exists is already reviewed, already tested, and already understood by the team.

## 1. Name each need

Write one line per piece the change needs: what it does in domain words, and its shape. For example, "format a price in cents for display, integer to string", or "find the players on a map that target an entity, entity to player list".

## 2. Search four ways

Run all four searches. One alone misses often.

- **By name.** Search the verbs and nouns and their synonyms in identifiers, such as format, render, and display, or total, sum, and calculate. Use `rg -n -i` with word boundaries.
- **By shape.** Search for functions that take or return the same type or record.
- **By neighbor.** Read what the code around the change already calls, and what its sibling files call. The helper you need is often one import away.
- **By behavior.** Search the literals the behavior touches: table names, routes, config keys, error messages, event names, and packet ids. Two places that touch the same table often hold the same logic.

Then check two more places.

- **The shared homes** this repository uses, such as `Helpers/`, `Services/`, `shared/`, `lib/`, `composables/`, or `hooks/`. Learn them from the tree, not from habit.
- **The framework and the installed dependencies.** Many needs are one call, such as date math, collection operations, validation, retries, or HTTP. Never hand-roll what an installed dependency does, and never add a dependency for what the stack already has.

If the project's instruction files name a semantic code search tool, use it next to `rg`. In a large codebase, spawn one read-only explorer per angle in parallel, on the `how explorer` model. Explorers return candidates with `file:line`, and you make every decision in step 3. Keep the scan to minutes.

## 3. Decide each need

- **Reuse** the existing code as it is. This is the default.
- **Extend** existing code with a small change that keeps one source of truth. List its callers first and confirm that none of them changes behavior. Run the **blast-radius** skill when you are not sure.
- **Write new code** only when nothing fits. Say in one line why the closest candidate does not fit. Put the code where the next reader would look for it: the shared home when a second caller is likely, next to its only caller otherwise.

If the change would add a third copy of logic that already exists twice, consolidate the two first, in their own commit, when that is small (**principle-subtract-before-you-add**). Otherwise list it as a follow-up and keep the change narrow.

Reuse means not writing the same logic twice. It does not mean forcing one abstraction onto code that only looks alike. Three similar lines beat a premature abstraction (**principle-foundational-thinking**).

## Output

Write the reuse brief as a table and pass it to every delegate that writes code.

| Need | Existing code | Decision | Why |
| --- | --- | --- | --- |
| Format a price for display | `server/src/pricing.js:12` `formatPrice` | Reuse | |
| Percent of an amount | `server/src/util/math.js:4` `percentOf` | Reuse | |
| Validate a discount code | None. Closest is `validateCoupon` in `legacy/`, which nothing calls. | New, in `server/src/discounts.js` | The legacy helper reads the old cart format. |

Add this rule to each delegate's brief: "Do not add a function, class, component, or query that is not in the reuse brief. If you need one, report the search that came up empty."

## Review a diff for duplication

For each new function, class, component, query, and config key in a diff, run step 2 once. New code that repeats existing code is a blocking finding. Name the existing code with `file:line` and the call that replaces the new code.
