---
name: harness:refactor
description: Use when boundary or ownership drift, recurring cleanup hotspots, or repository-declared commit-time refactor review require targeted architecture guidance.
---

# harness:refactor

Use this skill to find boundary and ownership drift in code or workflow structure when the repository still needs bounded cleanup, not a new enforcement rule.

`SKILL.md` is the complete default entry path. Open `PLAYBOOK.md` only when the finding needs extra judgment on severity, scope, or promotion.

## When To Use

Use `harness:refactor` when a diff, hotspot, or recurring review finding shows:

- boundary blur across folders, layers, entrypoints, adapters, or workflow surfaces
- file placement or naming that no longer matches ownership
- control flow or ownership drift that affects a future agent's ability to follow the boundary
- repeated boundary-ownership findings that should be turned into a refactor target
- repository metadata declares a commit-time refactor gate for staged source changes

Do not use this skill for stale docs, route drift, or designing new lint/test rules. Route those to `harness:doc-health` or `harness:lint-test-design` instead.

## Modes

### Review Mode

Use for a bounded architecture review of an active diff or hotspot. Output this mode as severity-ranked findings with boundary impact, action shape, and follow-up guidance.

### Governance Follow-Up Mode

Use when the same drift needs a contained cleanup map, sequencing, or a handoff into another governance skill. Output this mode as a short follow-up plan plus routing, not a fresh review pile.

## Minimal Flow

1. Start from the active diff or declared hotspot.
2. Inspect only the smallest adjacent boundary surface needed to judge the drift.
3. Classify findings by severity and action shape.
4. State whether the follow-up belongs in code now, in `harness:doc-health`, or in `harness:lint-test-design`.
5. If the repository declares a commit-time gate, review the staged snapshot and report `pass` or `must_refactor`.

## Required Output

- severity-ranked findings with file paths and line refs when available
- the affected boundary and why current checks may still pass
- the likely follow-up shape for each major finding: `rename`, `move`, `split`, `boundary test`, or `hardgate candidate`
- bounded cleanup guidance or follow-up routing
- proof expectation for any significant cleanup
- commit-time judgment when applicable

## Boundaries

- `harness:doc-health` owns stale or missing truth in specs, plans, READMEs, and route pointers.
- `harness:lint-test-design` owns encodeable rules, structural proofs, coverage expectations, and ratchets for recurring boundary findings.
- `harness:refactor` owns architecture drift findings and cleanup guidance when the current shape still needs human judgment.

## Commit-Time Gate

When repository metadata declares a commit-time refactor gate, inspect the staged snapshot and emit `pass` or `must_refactor` evidence for the local hook to validate.
