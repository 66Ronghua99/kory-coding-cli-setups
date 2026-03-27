---
name: harness:lint-test-design
description: Use when repository structure, ownership seams, coverage rules, or boundary rules need lint or test proof.
---

# harness:lint-test-design

`harness:lint-test-design` turns architecture intent into executable proof. The default path should be readable from this file alone; `PLAYBOOK.md` is optional guidance for judgment-heavy cases.

## Purpose

Use this skill when architecture rules need to become enforced proof instead of folklore.

## When To Trigger

- repository structure or ownership seams are drifting
- a recurring architecture comment should become a gate
- coverage rules need a clear expectation
- a transition needs an exception ledger and ratchet
- current code truth differs from the target model

Do not use this skill for a normal behavior bugfix, a generic architecture chat, or doc-only drift. Use `test-driven-development` for behavior changes, `harness:refactor` for architecture-drift discovery and review, and `harness:doc-health` when docs are out of sync with code truth.

## Frozen Truths

Freeze these three truths before choosing enforcement:

1. `target state` - the narrow end-state layer model, file-role model, and ownership model.
2. `current truth` - what the code actually does today.
3. `transition model` - the explicit gap, including temporary exceptions and ratchet triggers.

## Output Families

- `lint` for stable static invariants, path rules, and placement rules
- `structural test` for ownership edges, single-owner boundaries, and graph-shaped proof
- `behavior test` for runtime contracts and observable adapter behavior
- `coverage expectation` for changed code that needs explicit proof coverage
- `exception ledger` for temporary mismatches with an owner and exit path
- `ratchet` for tightening a rule after the temporary gap is no longer acceptable

`behavior test` here is the governance proof shape for runtime and boundary cases; `test-driven-development` still owns product behavior changes and writing those tests first.

## Minimal Flow

1. Freeze `target state`, `current truth`, and `transition model`.
2. Pick the smallest proof family that can fail clearly.
3. Record any exception ledger entry with owner, scope, reason, and exit path.
4. Add the ratchet or promotion rule that removes the gap over time.
5. Keep docs, lint, and tests describing the same truth.

## Boundaries

- `test-driven-development` owns behavior-first implementation discipline, not architecture governance.
- `harness:refactor` owns drift discovery and follow-up review, not long-lived enforcement design.
- `harness:doc-health` owns doc-to-code truth sync, not invariant modeling.
