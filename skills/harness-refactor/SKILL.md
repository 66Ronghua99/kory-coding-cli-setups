---
name: harness:refactor
description: Use when PR review, merge-to-main review, or governance cleanup needs architecture-drift guidance for agent-system workflow surfaces, boundary leaks, abstraction collapse, or recurring refactor hotspots that lint and tests do not fully explain.
---

# harness:refactor

`harness:refactor` is the golden standard for architecture drift findings and refactor guidance.

It does not ship a checker, runtime, or code rewrite engine. It tells coding agents how to inspect architecture drift, report severity-ranked findings, and recommend focused cleanup without collapsing document truth, lint/test design, and repository-local automation into one pass.

## Default Execution Mode

Run `harness:refactor` in a background subagent by default.

The main session should dispatch the review, keep working on non-overlapping critical-path tasks, and integrate the findings when they are needed. Do not run the full refactor audit inline in the main session unless the user explicitly forbids subagents or the environment cannot run them.

## Modes

### Review Mode

Use `review mode` at PR review or merge-to-main boundaries.

Required Inputs:

- active diff
- any known hotspot, boundary, or ownership context from the caller
- any known touched entrypoints, adapters, or public API surfaces

Start from the active diff, then expand only into bounded hotspots needed to judge architectural impact:

- directly affected modules
- adjacent boundary files
- touched entrypoints, adapters, or public API surfaces
- workflow surfaces linked to the diff, including tools, knowledge, handoffs, traces, or evaluation loops

`review mode` is diff-first and bounded. It must not degrade into an unbounded repository sweep.

### Governance Mode

Use `governance mode` for explicit cleanup work or when recurring drift shows that a narrow diff review is no longer enough.

Required Inputs:

- declared subsystem or target scope
- hotspot directories, modules, or workflow surfaces to inspect
- recurring findings, cleanup goal, or review history that explains why broader scanning is warranted

Start from a declared subsystem, hotspot directory, or repeated finding pattern. `governance mode` may scan the broader architecture surface because it is an intentional cleanup pass, but it must still stay scoped, prioritized, and repository-readable.

If the caller cannot provide the required inputs, stop and ask for bounded context instead of replacing it with an unbounded scan.

## When To Use

Use this skill when:

- PR review needs architecture drift findings, not only style comments
- merge-to-main review needs severity-ranked refactor guidance
- lint and tests still pass while workflow or ownership boundaries are collapsing
- agent-system architecture is becoming harder to read across tools, knowledge, handoffs, traces, or evaluation loops
- a subsystem needs a broader governance cleanup instead of another isolated comment thread
- repeated review findings suggest repository-local refactor planning or future hard gates may be needed

Do not use this skill for repository truth audits, pointer consistency, spec-plan-evidence freshness, or lint/test invariant design.

## Architecture Lens

Optimize for agent legibility first.

In agent systems, workflow is architecture. Review for whether models, tools, knowledge access, handoffs, traces, and evaluation loops remain explicit enough that a future coding agent can locate the boundary, understand the control flow, and change it safely.

Flag architecture findings such as:

- abstraction collapse or multi-responsibility files
- boundary leaks between workflow, orchestration, knowledge access, and core logic
- external shapes parsed too late or guessed deep inside business logic
- opaque or overly deep abstractions that future agents cannot reliably internalize
- repeated cleanup hotspots that keep reappearing because they are still folklore instead of repository truth or hard gates

## Severity

Use one severity ladder across both modes:

- `P0`: architecture break or unsafe boundary collapse that needs immediate containment; high severity
- `P1`: serious drift that materially harms maintainability or agent legibility; high severity
- `P2`: meaningful cleanup target that should be scheduled but does not require immediate containment
- `P3`: localized improvement or watchlist note

When this skill says severity-ranked findings, it means `P0` through `P3`. The defer-rationale rule applies to `P0` and `P1`.

## Required Outputs

### Review Mode Output

A `review mode` run should return:

1. findings summary with severity, file paths, and line references when available
2. merge guidance stating whether the change is acceptable as-is, should be narrowed, or needs focused refactor follow-up
3. bounded follow-up suggestions for the affected hotspots only
4. explicit defer rationale when high-severity findings are not fixed immediately

### Governance Mode Output

A `governance mode` run should return:

1. architecture debt map grouped by pattern or subsystem
2. prioritized refactor targets with rationale
3. suggested sequencing for cleanup work
4. a recommendation on whether a repository-local refactor plan artifact is warranted
5. follow-up routing when stale docs or enforceable invariants are discovered

## Advisory-First Policy

This shared skill is advisory-first.

High-severity findings may require an explicit defer rationale, but blocking merge policy, CI policy, PR policy, and escalation mechanics remain repository-local decisions.

## Boundary And Automation Rules

- repository-local `.workflow`, CI, merge, or PR automation stays outside the shared skill
- `harness:doc-health` owns repository truth, pointer consistency, and stale architecture docs
- `harness:lint-test-design` owns lint/test invariant design when repeated findings should become hard gates
- `harness:refactor` owns architecture drift findings and refactor guidance that remain even when docs and hard gates nominally exist

If review finds stale architecture truth, route the repair through `harness:doc-health` instead of silently treating it as resolved here. If repeated findings should become enforceable boundaries, route that follow-up into `harness:lint-test-design`.

## Guardrails

- Do not run the full audit inline when a background subagent can do it.
- Do not treat taste disagreements or formatting nits as architecture findings.
- Do not let `review mode` turn into unbounded scanning.
- Do not let `governance mode` collapse into vague "cleanup everything" advice.
- Do not merge document consistency work into this skill; route stale truth through `harness:doc-health`.
- Do not merge lint/test hardgate design into this skill; route enforceable follow-up through `harness:lint-test-design`.
- Do not use this skill to hide repository-local automation policy inside a shared governance pack.

## Reference Pack

- `references/agent-architecture-principles.md`
- `references/boundary-contracts.md`
- `checklists/` for mode-specific review checklists
- `examples/` for findings and follow-up shapes
