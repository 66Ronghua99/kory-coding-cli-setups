---
name: harness:lint-test-design
description: Use when recurring review comments or architecture rules should become lint or test invariants, especially for layers, file classification, dependency direction, complexity budgets, or regression control.
---

# harness:lint-test-design

`harness:lint-test-design` turns architecture intent into hard gates.

OpenAI's Harness approach is "enforce invariants, not implementations." This skill decides which repo rules belong in lint, tests, or docs-only guidance.

## When To Use

Use this skill when:

- folder structure, layer boundaries, or file classification are drifting
- import direction, deep imports, or permissible edges are unclear or repeatedly violated
- recurring review comments should become hard gates
- complexity, file size, naming, logging, or schema-boundary rules need mechanical enforcement
- a plan needs explicit lint/test evidence before implementation starts

Do not use this skill for pointer drift or general architecture review without an enforcement decision.

## Core Principle

Enforce invariants, not implementations.

- lint protects structure, dependency direction, naming, and size or complexity budgets
- structural tests protect layer graphs, allowed edges, and boundary contracts that need executable proof
- behavior tests protect runtime contracts and regressions
- docs explain the intent, exception policy, and rollout path

If a rule is repeated in review, decide whether it should be promoted into a repo-local hard gate.

## Hardgate Questions

- What is the canonical layer model or folder classification for this repo?
- Which directories, file kinds, or module roles are allowed?
- Which dependency directions and cross-cutting entrypoints are permitted?
- What should fail fast in lint, and what needs a structural or behavior test?
- What remediation message should the agent see when a rule fails?

## Working Shape

1. Freeze the architecture map and file classification model.
2. List the invariants worth enforcing.
3. Decide `lint`, `structural test`, `behavior test`, or `docs only` for each one.
4. Add severity, exception policy, and rollout phase.
5. Define passing and failing examples plus remediation guidance.
6. Make plans and evidence cite the resulting hard gates.

If the layer or folder model is missing, return that gap as a finding before proposing enforcement.

## Common Invariants

- domain layers and folder classification
- dependency direction and anti-cycle rules
- public API boundaries and anti-deep-import rules
- boundary validation for external data shapes
- file size, function size, and complexity budgets
- naming, logging, schema, and reliability conventions

## Required Output

- lint rule matrix
- test strategy matrix
- exception policy with owner, scope, and exit condition
- representative failing and passing cases
- evidence expectations for delivery

## Guardrails

- Do not stop at "reviewers prefer this" when the rule can be encoded.
- Do not use lint to micromanage implementation details.
- Do not leave folder roles, layer names, or allowed edges implicit.
- Do not allow exceptions without an owner and exit path.
- Do not keep recurring architecture feedback as folklore when lint or tests can carry it.

## Reference Pack

- `references/invariant-model.md`
- `references/lint-rule-taxonomy.md`
- `references/test-taxonomy.md`
- `references/severity-ladder.md`
- `references/exception-governance.md`
- `references/verification-evidence.md`
- `templates/lint-rule-matrix.template.md`
- `templates/test-strategy-matrix.template.md`
- `templates/lint-test-exception-policy.template.md`
- `templates/structural-test-cases.template.md`
- `checklists/lint-test-design-checklist.md`
- `examples/layered-boundaries.example.md`
- `examples/file-budget-and-coverage.example.md`
