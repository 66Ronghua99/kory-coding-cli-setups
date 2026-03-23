---
name: harness:lint-test-design
description: Use when repository structure, hard gates, coverage policy, file-role semantics, or recurring architecture feedback must become explicit lint/test proof with owned exceptions and ratchet rules instead of docs-only guidance.
---

# harness:lint-test-design

`harness:lint-test-design` turns architecture intent into executable proof.

The current Harness-style lesson is not just "add more lint." First freeze the target model, then record current truth, then use lint, structural tests, behavior tests, exception ledgers, and ratchets to pull the repo toward that model without silently normalizing drift.

## When To Use

Use this skill when:

- folder structure, layer boundaries, ownership seams, or file-role semantics are drifting
- recurring review comments should become hard gates instead of folklore
- coverage policy, changed-code proof, or whole-repo ratchets need to be designed
- singleton-owner rules matter, such as one composition root, one lifecycle owner, or one canonical adapter entrypoint
- current code truth differs from desired end-state and the repo needs explicit transitional hard gates
- a repository needs exception governance for temporary architectural mismatches
- docs, lint, tests, and hardgate outputs are no longer saying the same thing

Do not use this skill for generic architecture review unless the output should become an enforcement model.

## Core Model

Start by freezing three truths:

1. `target state`
   The narrow end-state layer model, file-role model, and ownership model the repo wants to converge to.
2. `current truth`
   What the code actually does today and which parts are already strong enough to prove mechanically.
3. `transition model`
   The explicit gap between current truth and target state, including temporary exceptions, rollout phases, and ratchet triggers.

If those three truths are blurred together, hard gates will either be too weak to stop drift or too dishonest to match the code.

## Core Principles

- Enforce invariants, not implementations.
- Path semantics are agent-facing contracts. Folder names, canonical owners, suffixes, and entrypoints must communicate responsibility without opening every file.
- Coverage is proof for changed code, not a vanity percentage.
- Structural proof matters as much as behavior proof. Many architecture regressions are about ownership, edges, or boundary leakage rather than user-facing behavior.
- Exception ledgers are transitional governance, not permanent escape hatches.
- Ratchets should tighten rules toward the target model; they should not widen the target model to fit drift.
- Docs, lint, tests, and hardgate outputs must describe the same repository truth.

## What Belongs Where

- `lint`
  Stable path rules, dependency direction, deep-import bans, singleton-owner path bans, file-role placement, naming rules, ambiguous-folder bans, file budgets, and other static graph or placement checks.
- `structural tests`
  Executable repo proofs that are easier to express in fixtures or graph assertions, such as shell-only assembly, lifecycle singletons, hook-free direct-call boundaries, or a narrow engine/application split.
- `behavior tests`
  Runtime contracts, adapter semantics, regressions, and observable behavior.
- `docs only`
  Only for rules that are not yet stable enough to prove mechanically. Docs-only means deliberately deferred, not forgotten.

## Hardgate Design Loop

1. Freeze the target layer model, file-role model, and canonical ownership model.
2. Record the current code truth and name the exact drift against the target.
3. Create an exception ledger only for temporary mismatches that are real, narrow, owned, and on a removal path.
4. For each invariant, choose `lint`, `structural test`, `behavior test`, or `docs only`.
5. For each chosen proof, define:
   - failure signal
   - remediation guidance
   - severity now
   - severity target
   - ratchet trigger
6. Separate steady-state rules from transitional allowances.
7. Make plans and evidence name the commands, fixtures, and artifacts that prove the boundary.

If the repository cannot name the canonical owner, allowed edges, or file roles, return that as the primary finding before proposing new gates.

## Hardgate Questions

- What is the target layer model?
- What is the current code truth?
- Which mismatches are temporary, and which are unacceptable immediately?
- Which canonical owners must remain singleton or uniquely reachable?
- Which boundaries need graph proof rather than behavior proof?
- Which changed-code coverage obligations are required now?
- Which whole-repo metrics or warning classes will ratchet later?
- What exact failure message should help the next agent self-correct?

## Coverage And Ratchet Policy

- default new or changed executable code to `100%` relevant line and branch coverage unless an explicit exception record says otherwise
- treat uncovered code as a classification problem: legacy debt, pending deletion, generated output, approved exception, or intentionally unproved docs-only surface
- whole-repo coverage, warning counts, and exception counts should ratchet in one direction only
- every warning or exception class should have a named promotion or removal trigger
- do not let transitional budgets silently become the permanent architecture

## Required Output

- target-state layer and file-role model
- current-truth summary
- invariant matrix
- lint rule matrix
- test strategy matrix
- structural proof matrix
- exception ledger with owner and exit path
- ratchet plan
- failing and passing examples
- evidence expectations for delivery

## Guardrails

- Do not widen the architecture model to fit current drift.
- Do not use lint to encode low-value implementation micromanagement.
- Do not rely on coverage alone when the real risk is ownership or boundary collapse.
- Do not allow ambiguous folders or new compatibility shells to survive by habit.
- Do not keep exceptions without owner, scope, reason, target phase, and removal trigger.
- Do not let docs claim a stronger or weaker truth than lint and tests actually prove.
- Do not leave recurring architecture feedback as oral tradition if a hard gate can carry it.

## Reference Pack

- `references/invariant-model.md`
- `references/lint-rule-taxonomy.md`
- `references/test-taxonomy.md`
- `references/severity-ladder.md`
- `references/exception-governance.md`
- `references/verification-evidence.md`
- `templates/lint-rule-matrix.template.md`
- `templates/test-strategy-matrix.template.md`
- `templates/structural-proof-matrix.template.md`
- `templates/ratchet-plan.template.md`
- `templates/lint-test-exception-policy.template.md`
- `templates/structural-test-cases.template.md`
- `checklists/lint-test-design-checklist.md`
- `examples/layered-boundaries.example.md`
- `examples/file-budget-and-coverage.example.md`
