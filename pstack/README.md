# pstack

pstack is a set of agent skills for disciplined engineering work. It guides coding agents to write smaller diffs, test their changes, and verify that the code works. [poteto](https://x.com/poteto) wrote the original. This fork runs pstack in Claude Code (including T3 Code), Codex, and Grok, and adds house rules for git, tests, code reuse, and comments.

## Install

See the [repository README](../README.md#install) for install commands. See [PORTABLE.md](./PORTABLE.md) for what the install does, model settings, and how this fork differs from upstream.

The installed skills come from the generated copy in `harness/pstack/claude-code/` at the repository root. After you edit `pstack/skills/`, `pstack/agents/`, or `pstack/plugin.json`, run `node scripts/generate-pstack-harness-trees.mjs` from the repository root and commit the source files and generated files together. CI fails until you do. Never edit `harness/pstack/` by hand.

## Get started

Follow two steps:

1. Run [`/setup-pstack`](./skills/setup-pstack/SKILL.md) to pick a reasoning budget and choose models per role.
2. Start tasks with [`/poteto-mode`](./skills/poteto-mode/SKILL.md) whenever the work needs engineering rigor.

The [pstack guide](./docs/guide/README.md) walks through a first real task, from setup and prompting to verification and overnight runs. If you are unsure which skill fits a task, run [`/poteto-help`](./skills/poteto-help/SKILL.md).

`/poteto-mode` calls the other skills as needed. In a Claude session, every role runs on Claude. Opus handles judgment, design, prose, and the hardest changes. Sonnet handles code, git history, and parallel workers. Haiku handles the `how` explorers. See [PORTABLE.md](./PORTABLE.md#models) for the reasoning behind these defaults. Run [`/setup-pstack`](./skills/setup-pstack/SKILL.md) to change any of them.

## Usage

Start a task with [`/poteto-mode`](./skills/poteto-mode/SKILL.md). It reads your request, selects one of 23 playbooks, and runs the other skills as each step needs them.

### Use [`/poteto-mode`](./skills/poteto-mode/SKILL.md)

Use `/poteto-mode` as the main entry point for engineering tasks. Examples:

```
/poteto-mode This PR has a subtle bug where the scroll drifts every 750ms even when idle. Repro first, then fix and verify.
```

```
/poteto-mode I am going to bed. Land the stack even if CI flakes. I want everything merged by morning.
```

<details>
<summary>All 23 playbooks</summary>

| Playbook | Use for |
|---|---|
| [Investigation](./skills/poteto-mode/playbooks/investigation.md) | Read-only questions about how something works, why it was built that way, or whether an assumption holds. |
| [Bug fix](./skills/poteto-mode/playbooks/bug-fix.md) | Reproducing a defect, finding its root cause, and fixing it with runtime evidence. |
| [Perf](./skills/poteto-mode/playbooks/perf-issue.md) | Tracing a measured slowness and improving it against a baseline. |
| [Hillclimb](./skills/poteto-mode/playbooks/hillclimb.md) | Improving one metric toward a target by testing hypotheses with before/after measurements and making one commit per accepted win. |
| [Runtime forensics](./skills/poteto-mode/playbooks/runtime-forensics.md) | Diagnosing a live symptom (leak, idle-CPU spin, or glitch) using instrumentation. |
| [Trace forensics](./skills/poteto-mode/playbooks/trace-forensics.md) | Diagnosing a captured profiling artifact (cpuprofile, trace, spindump, or heap snapshot). |
| [Feature](./skills/poteto-mode/playbooks/feature.md) | Adding or changing behavior, starting from a named data shape. |
| [Refactoring](./skills/poteto-mode/playbooks/refactoring.md) | Changing structure or shape without changing behavior. |
| [Prototype](./skills/poteto-mode/playbooks/prototype.md) | Building a throwaway sketch to make a design decision cheaply or settle an open question by running it. |
| [Visual parity](./skills/poteto-mode/playbooks/visual-parity.md) | Matching UI output pixel for pixel between two implementations. |
| [Authoring a skill](./skills/poteto-mode/playbooks/authoring-a-skill.md) | Writing or editing a `SKILL.md` file. |
| [Eval](./skills/poteto-mode/playbooks/eval.md) | Running a blind test of how a skill or prompt change affects agent behavior. |
| [Babysit](./skills/poteto-mode/playbooks/babysit.md) | Driving a PR or stack to merge-ready by handling conflicts, review threads, and CI. |
| [Shipping](./skills/poteto-mode/playbooks/shipping.md) | Independently verifying a green stack, then landing the verified PRs bottom-up through GitHub by default or Origin when available. |
| [Autonomous run](./skills/poteto-mode/playbooks/autonomous-run.md) | Driving a long task to completion without stopping. |
| [Orchestrate](./skills/poteto-mode/playbooks/orchestrate.md) | Running a standing multi-day project from one coordinator chat across stacked PRs and subagent fleets. |
| [Autopilot-full](./skills/poteto-mode/playbooks/autopilot-full.md) | Merging a queue of independent PRs with one owner per PR and a root swarm verdict on each round, from code-ready to merged. |
| [Autopilot-stack](./skills/poteto-mode/playbooks/autopilot-stack.md) | Building and verifying one linear base-branch stack for the operator to review and land. |
| [Session pickup](./skills/poteto-mode/playbooks/session-pickup.md) | Resuming or taking over another agent's in-flight work. |
| [Pause safely](./skills/poteto-mode/playbooks/pause-safely.md) | Suspending in-flight work cleanly so another session can resume it later. |
| [Multi-phase plan](./skills/poteto-mode/playbooks/multi-phase-plan.md) | Coordinating work that spans multiple phases or stacked PRs. |
| [Worktree cleanup](./skills/poteto-mode/playbooks/worktree-cleanup.md) | Reclaiming disk space by safely pruning merged or abandoned worktrees and stale iOS simulators. |
| [Opening a PR](./skills/poteto-mode/playbooks/opening-a-pr.md) | Opening a ready PR from small ordered commits with a Conventional Commits title and a short briefing body. Runs at the end of every other playbook. |

</details>

When invoked, `/poteto-mode` does three things:

1. Matches your task to a [playbook](./skills/poteto-mode/playbooks/) and opens a todo list whose first items are that playbook's steps, copied verbatim.
2. Routes to the other skills as each step needs them.
3. Writes direct, plain replies framed for the user and the maintainer.

The full rules and playbook triggers live in [`skills/poteto-mode/SKILL.md`](./skills/poteto-mode/SKILL.md).

## Skills

[`/poteto-mode`](./skills/poteto-mode/SKILL.md) invokes most of these skills automatically (`how`, `why`, `architect`, `arena`, `swarm`, `interrogate`, `unslop`, `no-comments`, `technical-writing`, `tdd`, and the principles). You can also invoke any skill directly:

```
/how Do we have an N+1 query when we look up every run to cancel?
```

```
/interrogate Review this PR.
```

<details>
<summary>All 33 skills</summary>

| Skill | Use when |
|---|---|
| [`/poteto-mode`](./skills/poteto-mode/SKILL.md) | You want the default entry point for any non-trivial task. |
| [`/poteto-help`](./skills/poteto-help/SKILL.md) | You are new to pstack or unsure which skill, playbook, or principle fits. Asks what you want to do, answers that question, and gives you a prompt to run. Runs only when you type `/poteto-help`. |
| [`/in-your-own-words`](./skills/in-your-own-words/SKILL.md) | You want the agent to restate your goal and the problem before starting. Runs only when you type `/in-your-own-words`. |
| [`/sharpen`](./skills/sharpen/SKILL.md) | You want a task framed like a domain expert would frame it, aimed at your real goal without overspecifying details or deciding choices for you. |
| [`/how`](./skills/how/SKILL.md) | You want a walkthrough of how a subsystem works. |
| [`/why`](./skills/why/SKILL.md) | You want to know why something was built a certain way. Discovers available MCPs at runtime and queries each evidence category in parallel (source control, issue tracker, long-form docs, real-time chat, infra observability, error tracking, and analytics warehouse). |
| [`/recall`](./skills/recall/SKILL.md) | You are starting or resuming work and want recent context rebuilt from your chat history and shared records into a short current-state brief. |
| [`/ketchup`](./skills/ketchup/SKILL.md) | You want a short plain-language summary of what changed in this chat since your last message, with small visuals and enough context to decide each action item. |
| [`/blast-radius`](./skills/blast-radius/SKILL.md) | You have a small-looking change and want to know what else it could break, with safety proven by running code rather than assumed. |
| [`/architect`](./skills/architect/SKILL.md) | You are about to write code across a function boundary and want caller usage, types, and module shape settled first. |
| [`/arena`](./skills/arena/SKILL.md) | You want N parallel attempts at the same task so you can combine the best parts of each. |
| [`/swarm`](./skills/swarm/SKILL.md) | You want N parallel workers across different slices or races, combined into one report. |
| [`/interrogate`](./skills/interrogate/SKILL.md) | You have a diff and want reviewer models to try to break it, including a strict code-quality review. |
| [`/automate-me`](./skills/automate-me/SKILL.md) | You want your own `<your-name>-mode` skill drafted from how you have worked in recent sessions. |
| [`/setup-pstack`](./skills/setup-pstack/SKILL.md) | You want to choose which models pstack uses per role. Detects available models and writes `~/.config/pstack/models.md`. |
| [`/reflect`](./skills/reflect/SKILL.md) | A long task has landed and you want the lessons captured as a skill edit. |
| [`/correct`](./skills/correct/SKILL.md) | You keep correcting agents for the same mistakes. Mines history for recurring mistakes, fixes each at the highest level that works (architecture, then types, lint, and CI, then tests, and docs last), and tracks each rule with what enforces it. |
| [`/teach`](./skills/teach/SKILL.md) | You want to understand a change or subsystem deeply rather than read a summary. Runs `how` and `why`, then builds one plain explanation diagram by diagram. |
| [`/tdd`](./skills/tdd/SKILL.md) | You are changing backend behavior. Writes tests from the requirement, commits them red, keeps them frozen while the code turns them green, and proves the cycle with `red-green.sh`. Skips frontend tests unless asked. |
| [`/project-conventions`](./skills/project-conventions/SKILL.md) | You are about to write code in a repository and need its rules, commands, and local patterns first. |
| [`/reuse-scan`](./skills/reuse-scan/SKILL.md) | You are about to write code the codebase may already have. Finds existing code to reuse, or justifies new code in one line. |
| [`/git-conventions`](./skills/git-conventions/SKILL.md) | You are branching, committing, or opening a PR. Enforces Conventional Commits, a `Why`/`Testing`/`Deployment` PR body, and no AI attribution. |
| [`/pstack-harness`](./skills/pstack-harness/SKILL.md) | Maps the tool and model names used in pstack skills to Claude Code, Codex, and Grok. Every skill that uses those names reads it first. |
| [`/benchmark-checklist`](./skills/benchmark-checklist/SKILL.md) | You ran a benchmark or measured a speedup or regression. Checks the number (limiter, tuning, errors, repeat runs, and end-to-end relevance) before you report or act on it. |
| [`/no-comments`](./skills/no-comments/SKILL.md) | You want to strip unneeded comments before review. Spawns Comment Sicko, fixes accepted findings, and offers structural encodings for claimed constraints. |
| [`/typescript-best-practices`](./skills/typescript-best-practices/SKILL.md) | You are reading or editing TypeScript. Applies the `type-system-discipline` principle in concrete TypeScript syntax. |
| [`/figure-it-out`](./skills/figure-it-out/SKILL.md) | No bundled playbook fits the task. Designs a custom, auditable playbook for it. |
| [`/show-me-your-work`](./skills/show-me-your-work/SKILL.md) | You want a reviewable decision trail. Logs decisions to a TSV file you can commit. |
| [`/create-verification-skill`](./skills/create-verification-skill/SKILL.md) | Your project has no scripted way to prove app behavior. Generates a project-local verify skill with a feature map for any language or platform. |
| [`/maintain-verification-skill`](./skills/maintain-verification-skill/SKILL.md) | Your verify skill's feature map has drifted from the app. Runs a source pass and one live pass, then produces at most one PR of proven corrections. |
| [`/unslop`](./skills/unslop/SKILL.md) | You are editing prose and want to remove AI writing tells. |
| [`/bro`](./skills/bro/SKILL.md) | You want the last message restated in plain human language without jargon. |
| [`/technical-writing`](./skills/technical-writing/SKILL.md) | You are writing docs, RFCs, READMEs, PR descriptions, or commit messages. Applies a layered style standard (Diátaxis, Google developer style, STE, and Global English). |

</details>

### Examples

Usually you start with [`/poteto-mode`](./skills/poteto-mode/SKILL.md) and let it pick a playbook and call other skills. You can also call individual skills directly.

<details>
<summary>All examples</summary>

```
Bug fix:           /poteto-mode This PR has a subtle bug where the scroll drifts every 750ms even
                   when idle. Repro first, then fix and verify.
Perf:              /poteto-mode A big list takes a second or two to load even though we virtualize.
                   Run a CPU trace and tell me why.
Feature:           /poteto-mode Build a small feature behind a feature flag. Verify it really works.
Prototype:         /poteto-mode Build two prototypes of the markdown renderer so we can compare.
                   Spawn an agent for each.
Multi-phase:       /poteto-mode Open source these skills as a plugin. Nothing internal leaks, work
                   in a temp dir, and show me the dependency graph first.
Overnight run:     /poteto-mode I am going to bed. Land the stack even if CI flakes. I want
                   everything merged by morning.
Babysit:           /poteto-mode Check on PR 123. Anything outstanding?
Visual parity:     /poteto-mode The row spacing is too tall when this flag is on. The second image
                   is correct. Repro and fix until it matches.
Figure it out:     /poteto-mode I am stepping away. Migrate every caller from the synchronous store
                   to the new async one, keeping behavior identical. I want to trust it was done
                   right when I am back.
How:               /how Do we cancel runs? Do we have an N+1 when we look up every run to cancel?
Why:               /why Why is this feature flag not on yet?
Architect:         Design this instrumentation to be high signal with no false positives. /architect
                   this first.
Arena:             /arena Take my prompt to the arena verbatim. I want to compare their proposals
                   with yours.
Swarm:             /swarm Check every package under packages/ against its check.sh. One worker per
                   package, one report.
Interrogate:       /interrogate Review this PR.
TDD:               /tdd Implement the new validation rules.
Unslop:            Can we unslop and tighten the new changes?
Reflect:           /reflect That took too long. Capture what we learned so the next run does not
                   repeat it.
Correct:           /correct
Show-me-your-work: /show-me-your-work Keep a decision trail I can review when I am back.
Automate-me:       /automate-me
Help:              /poteto-help Which skill should I use to review this branch?
```

</details>

## The `poteto-agent` and Comment Sicko subagents

[`/poteto-mode`](./skills/poteto-mode/SKILL.md) runs in the chat that receives it. That chat owns the playbook, the todo list, and every subagent spawn.

pstack ships [`subagent_type: "poteto-agent"`](./agents/poteto-agent.md) as the wrapper for delegates spawned during a run. It reads `poteto-mode` in full, including its inline principles index, before doing any work. Substituting `generalPurpose` skips that read and causes drift. Do not spawn `poteto-agent` to run the playbook itself.

[`/poteto-mode`](./skills/poteto-mode/SKILL.md) and [`subagent_type: "poteto-agent"`](./agents/poteto-agent.md) route through the same wrapper.

pstack also ships [Comment Sicko](./agents/comment-sicko.md), a comment reviewer available as `subagent_type: "comment-sicko"`. It removes unneeded comments and flags code to refactor without editing application code. Invoke it through [`/no-comments`](./skills/no-comments/SKILL.md) rather than directly.

## Principles

pstack includes 24 short skills, one principle each. `poteto-mode` indexes them inline and reads that index at task start. The standalone files let other skills reference a principle by name and let the index link to the full rule for each principle.

<details>
<summary>All 24 principles</summary>

| Principle | Group | Rule |
|---|---|---|
| [laziness-protocol](./skills/principle-laziness-protocol/SKILL.md) | Core | Bias toward deletion and the smallest change that solves the problem. |
| [foundational-thinking](./skills/principle-foundational-thinking/SKILL.md) | Core | Apply before writing logic when choosing core types and data structures, sequencing scaffold versus feature work, and deciding what concurrent actors share. Get the data structures right so downstream code becomes obvious. |
| [redesign-from-first-principles](./skills/principle-redesign-from-first-principles/SKILL.md) | Core | Redesign as if the requirement had been a foundational assumption from day one, instead of bolting it on. |
| [attack-the-premise](./skills/principle-attack-the-premise/SKILL.md) | Core | Apply when two or more fixes that share one premise have failed the same gate. Write the premise down and test it directly before writing another fix that assumes it. |
| [subtract-before-you-add](./skills/principle-subtract-before-you-add/SKILL.md) | Core | Remove dead weight, redundant validators, and stub references first, then build on the simpler base. |
| [minimize-reader-load](./skills/principle-minimize-reader-load/SKILL.md) | Core | Count the layers between question and answer and the hidden state a reader must hold in mind. Collapse one-caller wrappers and shrink mutable scope. |
| [outcome-oriented-execution](./skills/principle-outcome-oriented-execution/SKILL.md) | Core | Apply during planned rewrites and migrations with explicit phase boundaries. Converge on the target architecture instead of preserving smooth intermediate states with throwaway compatibility code. |
| [experience-first](./skills/principle-experience-first/SKILL.md) | Core | Choose user experience over implementation convenience. Ship fewer polished features instead of more rough ones. |
| [exhaust-the-design-space](./skills/principle-exhaust-the-design-space/SKILL.md) | Core | Build 2-3 competing prototypes and compare them side by side before committing. |
| [build-the-lever](./skills/principle-build-the-lever/SKILL.md) | Core | Apply to any non-trivial edits, migrations, analyses, or checks. Build a reusable tool that performs or proves the work (codemod, script, generator, or a skill for subagents) instead of doing it by hand. A reviewer can rerun that tool. |
| [model-the-domain](./skills/principle-model-the-domain/SKILL.md) | Architecture | Encode the domain in a structure instead of scattered conditionals. |
| [boundary-discipline](./skills/principle-boundary-discipline/SKILL.md) | Architecture | Concentrate guards at system boundaries (CLI, config, network, and external APIs). Trust internal types and keep business logic in pure functions. |
| [type-system-discipline](./skills/principle-type-system-discipline/SKILL.md) | Architecture | Make illegal states unrepresentable, brand semantic primitives, parse external data at boundaries, exhaust variants, and derive types from authoritative schemas. |
| [make-operations-idempotent](./skills/principle-make-operations-idempotent/SKILL.md) | Architecture | Converge to the same end state regardless of partial prior runs. |
| [migrate-callers-then-delete-legacy-apis](./skills/principle-migrate-callers-then-delete-legacy-apis/SKILL.md) | Architecture | Migrate callers and delete the old API in the same wave instead of keeping compatibility layers. |
| [separate-before-serializing-shared-state](./skills/principle-separate-before-serializing-shared-state/SKILL.md) | Architecture | Eliminate shared state first. Serialize structurally only when one shared writer is a real invariant. |
| [prove-it-works](./skills/principle-prove-it-works/SKILL.md) | Verification | Apply after completing a task, before declaring it done. Verify against the real artifact (run the feature, read the actual value, inspect the diff) instead of a proxy, self-report, or "it compiles". |
| [fix-root-causes](./skills/principle-fix-root-causes/SKILL.md) | Verification | Trace each symptom back to the first place the system went wrong and fix it there. A guard is a fix only when the state it handles is legitimate. |
| [sequence-verifiable-units](./skills/principle-sequence-verifiable-units/SKILL.md) | Verification | Apply to multi-step work (sweeps, migrations, and runs of similar edits) and to how you stack commits and PRs. Break work into small units that each end in a verifiable state, check each before the next, and order delivery so the sequence proves itself to a reviewer. |
| [test-behavior-not-implementation](./skills/principle-test-behavior-not-implementation/SKILL.md) | Verification | Apply when writing, changing, or keeping a test. Assert what the code's users can observe so the test fails when behavior breaks and keeps passing when only internals change. |
| [explain-the-number](./skills/principle-explain-the-number/SKILL.md) | Verification | Apply before trusting, reporting, or acting on a measured number (speedup, regression, throughput, latency, or eval result). Find what limits it and rule out that it measured something other than the work you think. |
| [guard-the-context-window](./skills/principle-guard-the-context-window/SKILL.md) | Delegation | Route bulk work to subagents. Keep summaries in the main thread instead of raw payloads. |
| [never-block-on-the-human](./skills/principle-never-block-on-the-human/SKILL.md) | Delegation | Proceed, present the result, and let the human course-correct afterward. Reserve confirmation for irreversible actions. |
| [encode-lessons-in-structure](./skills/principle-encode-lessons-in-structure/SKILL.md) | Meta | Encode the rule as a lint, metadata flag, runtime check, or script instead of more text. |

</details>

## Companion skills

`poteto-mode` also calls `deslop`, `control-cli` (for CLIs and TUIs), and `control-ui` (for browser, Electron, and web UIs). Their sources live in `cursor-team-kit/skills/` at the repository root, and the generated tree copies them beside the pstack skills. The [harness skill](./skills/pstack-harness/SKILL.md) maps `create-skill` to each host's own skill-writing guidance.

## Why are there no planning skills?

The best spec is code. If you need a plan, [`/poteto-mode`](./skills/poteto-mode/SKILL.md) includes a multi-phase plan playbook, but it is not the default.

## Make it yours

`poteto-mode` reflects poteto's style. You can adapt it to yours.

Run [`/automate-me`](./skills/automate-me/SKILL.md). It mines your recent transcripts, drafts a `<your-name>-mode` skill from how you have worked, and routes through pstack underneath. You keep pstack as the base and gain your own routing skill alongside `poteto-mode`.

Models are configurable too. Run [`/setup-pstack`](./skills/setup-pstack/SKILL.md). It detects the models you have access to and writes `~/.config/pstack/models.md`, which maps each role (code, judgment, and the review panels) to a model. Every skill reads that file and falls back to defaults when the file is absent, so you override only what you want.

When a default changes, a file written before the change still pins the old default. Delete those role lines, or delete the file, then run `/setup-pstack` again. A rerun keeps any role whose model differs from the default.

## License

MIT
