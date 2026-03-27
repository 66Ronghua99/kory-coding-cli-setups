# Agent Index

## Default Route

1. Load `using-superpowers`.
2. Read `PROGRESS.md`, `NEXT_STEP.md`, `MEMORY.md`, and `.harness/bootstrap.toml` if present.
3. For runtime failure, regression, or unexpected behavior, start in `systematic-debugging`.
4. For feature, behavior, workflow, or approved bugfix coding, start in `test-driven-development`.
5. Add `harness:refactor` as a structural triage overlay for cross-layer changes, file moves, ownership changes, or drifting boundaries.
6. Promote into `harness:lint-test-design` when a finding should become mechanical proof.
7. Route repository truth sync, pointer drift, or stale spec/plan/evidence links to `harness:doc-health` only.
8. Core lifecycle routes stay visible:
   - repository bootstrap or governance baseline setup -> `harness:init`
   - new feature, behavior, or workflow design -> `brainstorming`
   - approved spec or frozen requirement -> `writing-plans`
   - start of implementation needing isolation -> `using-git-worktrees`
   - plan execution with subagents -> `subagent-driven-development`
   - plan execution without that mode -> `executing-plans`
   - delivery review -> `requesting-code-review`
   - completion claim -> `verification-before-completion`
   - branch or worktree wrap-up -> `finishing-a-development-branch`

## Bootstrap Rule

If `.harness/bootstrap.toml` exists, treat it as the machine-readable bootstrap source of truth.

- Any commit-time `harness:refactor` gate belongs in bootstrap metadata as a deferred automation note, not as part of the primary route story.
- Bootstrap route hints should stay additive and soft unless a separate automation spec explicitly consumes them.
