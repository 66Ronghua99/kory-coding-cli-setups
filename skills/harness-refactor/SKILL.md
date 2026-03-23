---
name: harness:refactor
description: Use when architecture drift, readability decay, recurring cleanup hotspots, or repository-declared commit-time refactor review require targeted architecture guidance.
---

# harness:refactor

`harness:refactor` is for architecture drift that still exists after docs and hard gates.

OpenAI's Harness model treats refactoring like garbage collection: small, repeated cleanup that keeps the codebase legible for future agent runs. This skill scopes those cleanups without replacing doc-health or lint/test design.

## When To Use

Use this skill when:

- a PR or merge review needs architecture findings, not style feedback
- files or modules are collapsing across responsibilities even though tests still pass
- folder structure, layer placement, or ownership boundaries are becoming hard to read
- repeated cleanup hotspots suggest a targeted refactor pass
- a subsystem needs a bounded cleanup map before more work lands
- repository metadata declares a commit-time refactor gate for the current staged source changes

Do not use this skill for stale repo docs or for deciding new hard gates without a concrete enforcement follow-up.

## Commit-Time Triggering

When repository metadata defines a commit-time refactor gate, treat lightweight `review mode` as mandatory for staged source changes that match the repository's declared trigger paths.

- prefer proactive review before `git commit` instead of waiting for a hook failure
- prefer subagent execution for commit-time review
- inspect the staged snapshot version of each matched file plus only the smallest adjacent boundary surface needed for architecture judgment
- write fresh local gate evidence to `<cwd>/superpowers/artifacts/refactor-gate/<stamp>.md`
- let the repository-local hook validate current-snapshot pass evidence; do not turn this shared skill into the hook runner
- if commit-time review returns blocking findings, refactor or narrow the change before retrying commit

## Core Lens

Optimize for agent legibility.

Ask whether a future agent can:

- find the right folder or layer without guessing
- understand each file's role from its location and dependencies
- see where external shapes are validated
- modify one concern without touching three unrelated ones
- tell whether the real fix is refactor, docs repair, or a new hard gate

## File-Internal Scope

This skill may inspect file-internal code, but only when the internal structure materially affects architecture boundaries, ownership, path semantics, or future agent legibility.

Inspect file-internal problems such as:

- multi-responsibility files that blur ownership or layer boundaries
- boundary parsing or validation living in the wrong layer
- abstractions that hide control flow and make safe edits harder
- file contents that no longer match the file name, path, or declared module role
- file sprawl large enough to reduce agent comprehension or safe modification

Do not inspect or report:

- formatting, style, or taste-only concerns
- ordinary local cleanup with no architecture impact
- micro-refactors that belong in normal code review
- issues already better handled by lint, structural tests, behavior tests, or general delivery review

## Agent-Facing File Semantics

- treat file paths, folder names, and filenames as interfaces future agents rely on during search and navigation
- treat generic folders such as `shared/`, `helpers/`, or `utils/` as potential architecture hotspots when they absorb subsystem-owned code
- call out path or naming semantics that mislead a future agent even when runtime behavior still works
- distinguish between "internals are messy" and "the file system now lies about responsibility"

## Refactor Action Shapes

Every finding should classify the most likely follow-up shape:

- `rename`
- `move`
- `split`
- `boundary test`
- `hardgate candidate`

## Working Shape

1. Start from a diff or declared hotspot, not a full-repo sweep.
2. Trace the smallest set of files needed to judge the boundary.
3. Report severity-ranked findings with concrete refactor targets and an action shape.
4. Say whether the issue should be fixed in code now, deferred, routed to `harness:doc-health`, or promoted to `harness:lint-test-design`.
5. State what proof should accompany the cleanup, such as a boundary test, structural test, or tighter coverage expectation.
6. When the same issue keeps recurring, recommend a recurring cleanup or targeted refactor PR shape.

If the repo does not define a clear layer or folder model, report that missing model explicitly instead of guessing one.
If commit-time review is active, also report whether the current staged snapshot is `pass` or `must_refactor`.

## Common Findings

- multi-responsibility files that blur domain layers
- filenames or paths that no longer describe file responsibility
- folder placement that no longer matches file responsibility
- boundary validation happening too deep in the stack
- cross-cutting concerns leaking past their intended entrypoints
- generic shared folders absorbing subsystem-owned code
- repeated helper proliferation where shared utilities should exist
- abstractions that hide control flow instead of clarifying it

## Severity

- `P0`: unsafe boundary collapse or architecture break
- `P1`: serious drift that materially harms legibility or maintainability
- `P2`: worthwhile cleanup target that should be scheduled
- `P3`: localized improvement or watchlist note

## Required Output

- findings summary with severity, file paths, and line references when available
- bounded cleanup guidance for the affected hotspot
- action shape for each finding such as `rename`, `move`, `split`, `boundary test`, or `hardgate candidate`
- defer rationale for any `P0` or `P1` not fixed now
- recommendation on whether to route follow-up into docs, hard gates, or recurring cleanup
- proof expectation for any significant cleanup so the next agent knows how the refactor will be verified
- for commit-time review, an explicit `pass` or `must_refactor` judgment for the current staged snapshot

## Guardrails

- Do not turn this into an unbounded repo sweep by default.
- Do not report formatting nits or taste-only comments as refactor findings.
- Do not use this skill as a catch-all for ordinary file-internal cleanup with no architecture impact.
- Do not keep repeating the same advice if the real need is a lint or structural test.
- Do not repair stale source-of-truth docs here; route them through `harness:doc-health`.
- Do not hide enforcement design here; route encodeable rules through `harness:lint-test-design`.
- Do not wait for a problem to become folklore if it is already stable enough to become a hardgate candidate.
- Do not let commit-time review degrade into `governance mode` or a full-repository sweep.

## Reference Pack

- `references/agent-architecture-principles.md`
- `references/boundary-contracts.md`
- `checklists/` for mode-specific review checklists
- `examples/` for findings and follow-up shapes
