---
name: reuse-scan
description: "Search the codebase for code that already does what you are about to write, then reuse it, extend it, or justify new code in one line. Returns a reuse brief for delegates. Use for /reuse-scan, before writing any new function, class, component, endpoint, query, or helper, and when reviewing a diff for duplication."
disable-model-invocation: true
---

# Reuse scan

Read [the pstack harness skill](../pstack-harness/SKILL.md) once per session before you follow this skill. It maps the tool and model names in pstack skills to Claude Code and Codex.

Every line you add is a line a teammate maintains by hand. Before you write something, show that the codebase does not already have it. Code that already exists is already reviewed, already tested, and already understood by the team.

## 1. Name each need

Write one line per piece the change needs: what it does in domain words, and its shape. For example, "format a price in cents for display, integer to string", or "find the players on a map that target an entity, entity to player list".

Name the need as the outcome, not as a mechanism. An audit, issue, review comment or ticket often proposes a fix such as "add an allowlist" or "add a permission check". That is the result that must hold, not the way to build it. Write "accept only these request fields", not "write an allowlist array". A need named as a mechanism only finds that mechanism, and misses the module the project already uses for the job.

## 2. Search five ways

Run all five searches. One alone misses often.

- **By precedent.** Ask how this codebase already solves this kind of problem, then find two or three places that do it. Search the problem class, not your planned code. Input that must be limited or checked leads to the project's validator or request objects. Access rules lead to its policy or privilege checks. A query leads to its query builder or repository. Read the sibling endpoints, handlers or components that face the same problem. When the project has a module for the job, using it is the default, even if a few lines of your own would also work.
- **By name.** Search the verbs and nouns and their synonyms in identifiers, such as format, render, and display, or total, sum, and calculate. Use `rg -n -i` with word boundaries.
- **By shape.** Search for functions that take or return the same type or record.
- **By neighbor.** Read what the code around the change already calls, and what its sibling files call. The helper you need is often one import away.
- **By behavior.** Search the literals the behavior touches: table names, routes, config keys, error messages, event names, and packet ids. Two places that touch the same table often hold the same logic.

Then check two more places.

- **The shared homes** this repository uses, such as `Helpers/`, `Services/`, `shared/`, `lib/`, `composables/`, or `hooks/`. Learn them from the tree, not from habit.
- **The framework and the installed dependencies.** Many needs are one call, such as date math, collection operations, validation, retries, or HTTP. Never hand-roll what an installed dependency does, and never add a dependency for what the stack already has.

If the project's instruction files name a semantic code search tool, use it next to `rg`. In a large codebase, spawn one read-only explorer per angle in parallel, on the `how explorer` model. Explorers return candidates with `file:line`, and you make every decision in step 3. Keep the scan to minutes.

## 3. Decide each need

- **Reuse** the existing code as it is. This is the default. A project module built for the job, such as a validator, a policy layer or a query builder, beats a hand-written array, loop or check, even a short one.
- **Extend** existing code with a small change that keeps one source of truth. List its callers first and confirm that none of them changes behavior. Run the **blast-radius** skill when you are not sure.
- **Write new code** only when nothing fits. Say in one line why the closest candidate does not fit. Put the code where the next reader would look for it: the shared home when a second caller is likely, next to its only caller otherwise.

If the change would add a third copy of logic that already exists twice, consolidate the two first, in their own commit, when that is small (**principle-subtract-before-you-add**). Otherwise list it as a follow-up and keep the change narrow.

Reuse means not writing the same logic twice. It does not mean forcing one abstraction onto code that only looks alike. Three similar lines beat a premature abstraction (**principle-foundational-thinking**).

### Know what each call does

Before you call a method you reuse, read its body, not only its name, signature or docblock. Write down in one line what it returns and what it already filters, defaults, checks or throws. Then call only what the outcome needs.

- Every call in a chain must change the result. If you remove a call and the result stays the same for every input, that call is redundant. Delete it. For example, a field filter before a validator that already returns only the fields that have rules adds nothing.
- A sibling call site shows which module to use. It does not prove that each call in it is needed. Copy its shape only after you know what each call does. If a sibling has a redundant call, do not copy it.
- Prefer the shortest call that gives the outcome. Optional steps, wrappers and helper calls earn their place only by changing the result.

## Output

Write the reuse brief as a table and pass it to every delegate that writes code.

| Need | Existing code | Decision | Why |
| --- | --- | --- | --- |
| Format a price for display | `server/src/pricing.js:12` `formatPrice` | Reuse | |
| Percent of an amount | `server/src/util/math.js:4` `percentOf` | Reuse | |
| Validate a discount code | None. Closest is `validateCoupon` in `legacy/`, which nothing calls. | New, in `server/src/discounts.js` | The legacy helper reads the old cart format. |

Add this rule to each delegate's brief: "Do not add a function, class, component, or query that is not in the reuse brief. If you need one, report the search that came up empty. Before you report back, run the redundancy pass from the reuse-scan skill's 'Review a diff for duplication' section on your diff."

## Review a diff for duplication

For each new function, class, component, query, and config key in a diff, run step 2 once. New code that repeats existing code is a blocking finding. Name the existing code with `file:line` and the call that replaces the new code.

Then read the diff for redundancy inside it and around it. Run this pass on your own diff before every commit, not only on someone else's. Each hit is a blocking finding:

- **The same value computed twice.** A length, a lookup, a query, or a parse that two methods or two branches repeat from inputs that do not change. Compute it once, in the constructor, a property, or a local, and pass it on.
- **A second mechanism for a job already done.** Before you add a default, a filter, a guard, or a fallback, trace the value from where it enters to where you use it. That includes the caller, the parent component, the props, and the layer above. If something on that path already does the job, use it and add nothing.
- **A call that changes nothing.** For each method call in the diff, read the called method's body. If the call can be removed and the result stays the same for every input, it is redundant. This includes a call copied from a sibling call site. See "Know what each call does".
- **A check repeated across layers.** If a boundary already guarantees a value, such as a parser, a DTO, or a validated request, the code behind it trusts that value. Keep a second check only when it guards a different failure, and name that failure. A loose check that runs before a stricter one, such as a format regex before a lookup in the real list, is the same redundancy.
- **The same rule in two places.** One rule, such as which text to translate or which languages to skip, lives in one function that every caller uses. Two copies drift apart. This includes a backend rule copied into the frontend: have the backend send it.
- **Dead weight.** An import, prop, computed value, parameter, CSS class, or branch that nothing reads. A response field the client never reads. A branch no real caller can reach: check what the client actually sends before you handle another shape. A wrapper with one caller that adds nothing.
- **A refactor that does more work than the code it replaced.** When you route existing code through a new helper, keep its early exits, and count its queries and loops before and after. Loading the same table twice in one request is the same value computed twice.
- **A shared helper that changes an old caller.** When you extract a helper from existing code, compare what each old caller did before and after. Keep the old behavior, or name the change in the PR.
- **Tests that repeat each other.** Two tests that assert the same thing, a test that does not exercise the path its name describes, or a database test for a constant that a unit test can check. Also a test that proves again what a reused module's own tests prove, a test that lists every field or rule of the code again, and two tests for one behavior that one mechanism handles. See "Test only what the change adds" in the **tdd** skill.

One more check that is not redundancy but hides as it: when one piece of code only works because another trims, sorts, or filters first, say so in a comment where that step happens. Otherwise the next reader removes the step as noise.

Re-read every file you touched from top to bottom once, not only the hunks. Redundancy hides between a new hunk and an old line that the diff view does not show.
