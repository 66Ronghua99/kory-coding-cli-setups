---
name: harness:refactor
description: Use when architecture drift, readability decay, or recurring cleanup hotspots need targeted refactor guidance that docs and hard gates do not fully cover.
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

Do not use this skill for stale repo docs or for deciding new hard gates without a concrete enforcement follow-up.

## Core Lens

Optimize for agent legibility.

Ask whether a future agent can:

- find the right folder or layer without guessing
- understand each file's role from its location and dependencies
- see where external shapes are validated
- modify one concern without touching three unrelated ones
- tell whether the real fix is refactor, docs repair, or a new hard gate

## Working Shape

1. Start from a diff or declared hotspot, not a full-repo sweep.
2. Trace the smallest set of files needed to judge the boundary.
3. Report severity-ranked findings with concrete refactor targets.
4. Say whether the issue should be fixed in code now, deferred, routed to `harness:doc-health`, or promoted to `harness:lint-test-design`.
5. When the same issue keeps recurring, recommend a recurring cleanup or targeted refactor PR shape.

If the repo does not define a clear layer or folder model, report that missing model explicitly instead of guessing one.

## Common Findings

- multi-responsibility files that blur domain layers
- folder placement that no longer matches file responsibility
- boundary validation happening too deep in the stack
- cross-cutting concerns leaking past their intended entrypoints
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
- defer rationale for any `P0` or `P1` not fixed now
- recommendation on whether to route follow-up into docs, hard gates, or recurring cleanup

## Guardrails

- Do not turn this into an unbounded repo sweep by default.
- Do not report formatting nits or taste-only comments as refactor findings.
- Do not keep repeating the same advice if the real need is a lint or structural test.
- Do not repair stale source-of-truth docs here; route them through `harness:doc-health`.
- Do not hide enforcement design here; route encodeable rules through `harness:lint-test-design`.

## Reference Pack

- `references/agent-architecture-principles.md`
- `references/boundary-contracts.md`
- `checklists/` for mode-specific review checklists
- `examples/` for findings and follow-up shapes
