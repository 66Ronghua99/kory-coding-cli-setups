---
name: harness:lint-test-design
description: Use when defining or evolving code invariants so lint and tests become the hard boundary that prevents architectural drift, complexity drift, and behavior regressions.
---

# harness:lint-test-design

`harness:lint-test-design` is the golden standard for turning architecture intent into lint and test boundaries.

It does not ship a gate runner. It tells coding agents how to decide which invariants belong in lint, which belong in tests, how to roll them out, and how to record the resulting quality boundary in repository docs and plans.

## When To Use

Use this skill when:

- architecture rules exist but are enforced only by review comments
- import direction, deep imports, or layer boundaries keep drifting
- complexity, file growth, or abstraction collapse is showing up repeatedly
- a repository needs a reusable lint/test hardgate design, not just one-off fixes
- a plan needs explicit lint/test evidence expectations before implementation begins

Do not use this skill for document truth audits or bootstrap initialization.

## Core Principle

Lint and tests are the hard boundary for repository invariants.

- lint protects structure, direction, and complexity budgets
- tests protect behavior, contracts, and regression boundaries
- both must be designed intentionally, rolled out explicitly, and documented in a way future agents can reuse

## Required Inputs

- architecture source of truth (`docs/architecture/layers.md` or equivalent)
- testing strategy (`docs/testing/strategy.md` or equivalent)
- current lint config and test stack
- known review hotspots and recurring regressions

## Required Outputs

- lint rule matrix
- test strategy matrix
- lint/test exception policy
- structural or contract test case plan
- severity ladder and rollout policy
- evidence expectations for delivery

## Workflow

1. Freeze the architecture graph and core code invariants.
2. Decide whether each invariant belongs in lint, tests, or both.
3. Define severity, rollout phase, and exception policy.
4. Define representative passing and failing examples.
5. Publish the matrix, templates, and checklists into repository docs.
6. Make implementation plans cite the relevant lint/test invariants and required evidence.

## Invariant Families

- dependency direction and anti-cycle
- public API boundaries and anti-deep-import rules
- file/function size and complexity budgets
- infrastructure entrypoint control
- contract, structural, integration, and regression test coverage
- naming, type, and schema boundary consistency

## Guardrails

- Do not treat lint as formatting-only policy.
- Do not treat tests as coverage theater.
- Do not leave severity or rollout state implicit.
- Do not allow exceptions without owner, scope, and exit condition.
- Do not rely on memory or review folklore for architecture boundaries that can be expressed as lint/test invariants.

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
