# Shared Agent Index

This file is the fallback routing table when a repository does not yet provide its own `AGENT_INDEX.md`.

## Default Route

1. Load `using-superpowers`.
2. Read `PROGRESS.md`, `NEXT_STEP.md`, `MEMORY.md`, and `.harness/bootstrap.toml` if present.
3. Route by task type:
   - repository bootstrap or governance skeleton setup -> `harness:init`
   - new feature / behavior / workflow change -> `brainstorming`
   - approved spec / frozen requirement -> `writing-plans`
   - start of implementation needing isolation -> `using-git-worktrees`
   - plan execution with subagents -> `subagent-driven-development`
   - plan execution without that mode -> `executing-plans`
   - feature or bugfix code -> `test-driven-development`
   - runtime failure / regression / unexpected behavior -> `systematic-debugging`
   - repository truth, pointer drift, or stale spec/plan/evidence links -> `harness:doc-health`
   - lint/test invariant, structural hardgate, or recurring review issue that should become mechanical -> `harness:lint-test-design`
   - architecture drift, boundary erosion, or proactive refactor governance -> `harness:refactor`
   - delivery review -> `requesting-code-review`
   - completion claim -> `verification-before-completion`
   - branch / worktree wrap-up -> `finishing-a-development-branch`

## Governance Split

- `Superpowers` owns scope freeze, planning, execution, review, and completion verification.
- `Harness` owns repository truth, invariant design, and architecture-governance standards.
- `Harness` should intervene at route time for governance-specific tasks, during planning as a constraints source, during execution only when drift or boundary issues surface, and again before completion as a truth-and-invariants backstop.

## Fallback Agent Roles

### `explorer`
- Use for read-only repository discovery, evidence gathering, and path tracing.

### `architect`
- Use for boundaries, interfaces, migration shape, and compatibility decisions.

### `reviewer`
- Use for correctness, regression, safety, and missing-test review.
