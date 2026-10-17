---
name: tdd
description: "Test-first for backend behavior: understand the task, write tests that fail, commit them red, then implement until they pass without editing them. No frontend tests unless the user asks. Use for /tdd, and for every feature or bug fix that changes backend behavior."
disable-model-invocation: true
---

# Test-driven development

Tests come from the requirement, not from the code. An implementation written first, with tests shaped afterward to pass, proves only that the code does what the code does. It misses the edge cases the task named and gives false confidence.

## Which code gets tests

- **Backend behavior gets tests, written first.** Backend means code that runs on a server or in a CLI: domain logic, services, handlers, controllers, jobs, data access, serialization, and APIs. A change to its behavior gets a test whenever a test can observe that behavior at a sane cost.
- **Frontend code gets no tests unless the user asks.** Frontend means code that runs in a browser or a UI client: components, views, templates, styles, client stores, and client-side helpers inside a frontend app or package. Do not write unit, component, snapshot, or end-to-end tests for it, and do not run its test suites. Verify it with the project's type check, lint, and build. List what a person should check by hand under `## Testing` in the PR, per the **git-conventions** skill. Drive the running UI with `control-ui` only to reproduce a visual or interaction bug, or when the user asks.
- **Project rules win.** If the repository's instruction files set a different policy, follow them (**project-conventions** skill).
- **Code without behavior gets no test,** such as config wiring, a rename, a pure move, or log text. Write `tests: n/a, <reason>`.

## Workflow

1. **Understand the task before any code.** List the behaviors the change must have, as a reviewer could check them: the main path, each edge case the task implies (empty, zero, limit, duplicate, missing, unauthorized, concurrent, repeated), and each failure. Derive expected values from the requirement, never from running code. When the task leaves a behavior open, state what you assumed.
2. **Pick the narrowest test that observes each behavior.** Use the test style the repository already uses for that layer, and assert what users of the code can observe (**principle-test-behavior-not-implementation**). Prefer real collaborators, such as an in-memory database or the real parser, over mocks of your own code. Mock only a boundary you do not own.
3. **Write the tests, run them, and watch them fail for the right reason.** The failure must come from the missing behavior: a wrong value, a missing record, a not-implemented error. A compile error or a crash in setup is not red yet. When a test needs a symbol that does not exist, add its signature with a not-implemented body in the same commit, so the test compiles and fails on behavior.
4. **Commit the red tests before any implementation,** as `test(<scope>): <behavior>`. Prove red with `scripts/red-green.sh --red HEAD -- <test command>`, from this skill's folder.
5. **Implement until green without touching the tests.** The tests are frozen from the red commit on. Make the smallest change that passes them and keeps nearby contracts. If a test encodes a wrong requirement, stop. Fix the test in a new red commit, say why, and prove red again. Never edit a test to fit the implementation.
6. **Prove the cycle.** Run `scripts/red-green.sh --red <red commit> -- <test command>`. It checks that the tests failed at the red commit, pass at HEAD, and did not change in between. Then run the full backend suite from the project brief.

When a delegate implements, a different agent writes the tests: the parent, or a test-author delegate that gets only the requirement and the behavior list. The implementer gets the frozen tests and step 5 as its rule.

## Existing tests

- **A failing existing test is a signal, not an obstacle.** Find out why it fails before you touch it. Your change broke behavior someone relies on, the test already failed on the base branch, or the requirement changed. Check the base branch to tell these apart. Fix the cause. Change the test only when the task's own requirement makes its old expectation wrong, and say so.
- **Never weaken an assertion, skip a test, or delete one to get green.** Never change an expected value to match new output without naming the requirement that changed it. `red-green.sh` warns when the red commit edits an existing test. Answer that warning in your report.

## When a test is impractical

Some backend behavior has no sane test path, such as production-only state, hardware, or a third party with no sandbox. Use the closest executable check instead, such as a script, a command with captured output, or a log assertion, and say why. A bad test is worse than none. A bad test mostly tests mocks, pins implementation details, depends on timing, or gets deleted right after the fix.

## Report

- The behavior list from step 1.
- The red commit and the failure output that proves red.
- The `red-green.sh` result and the full-suite result.
- Each existing test you changed, with the requirement that justified it.
- For a frontend change, `tests: n/a, frontend` and the checks you ran instead.
