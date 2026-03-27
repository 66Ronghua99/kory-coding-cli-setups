# Shared Agent Index

This file is the fallback routing table when a repository does not yet provide its own `AGENT_INDEX.md`.

## Default Route

1. Load `using-superpowers`.
2. Read `PROGRESS.md`, `NEXT_STEP.md`, `MEMORY.md`, and `.harness/bootstrap.toml` if present.
3. For runtime failure, regression, or unexpected behavior, start in `systematic-debugging`.
4. For feature, behavior, workflow, or approved bugfix coding, start in `test-driven-development`.
5. Add `harness:refactor` as a structural triage overlay when the work also involves cross-layer changes, file moves or ownership changes, boundary-facing shells/adapters/workflows/composition surfaces, or repeated signals that the structure is drifting.
6. Promote into `harness:lint-test-design` when a finding should become mechanical proof such as a lint rule, structural test, coverage expectation, exception ledger entry, or ratchet.
7. Route repository truth sync, pointer drift, or stale spec/plan/evidence links to `harness:doc-health` only.
8. Other Superpowers routes:
   - repository bootstrap or governance skeleton setup -> `harness:init`
   - new feature / behavior / workflow design -> `brainstorming`
   - approved spec / frozen requirement -> `writing-plans`
   - start of implementation needing isolation -> `using-git-worktrees`
   - plan execution with subagents -> `subagent-driven-development`
   - plan execution without that mode -> `executing-plans`
   - delivery review -> `requesting-code-review`
   - completion claim -> `verification-before-completion`
   - branch / worktree wrap-up -> `finishing-a-development-branch`

## Governance Split

- `Superpowers` owns scope freeze, planning, execution, review, and completion verification.
- `Harness` owns repository truth sync, structural triage, invariant design, and architecture-governance standards.

## Fallback Agent Roles

### `explorer`
- Use for read-only repository discovery, evidence gathering, and path tracing.

### `architect`
- Use for boundaries, interfaces, migration shape, and compatibility decisions.

### `reviewer`
- Use for correctness, regression, safety, and missing-test review.
