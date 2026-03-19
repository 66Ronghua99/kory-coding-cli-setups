# Shared Agent Index

This file is the fallback routing table when a repository does not yet provide its own `AGENT_INDEX.md`.

## Default Route

1. Load `using-superpowers`.
2. Read `PROGRESS.md`, `NEXT_STEP.md`, and `MEMORY.md`.
3. Route by task type:
   - new feature / behavior / workflow change -> `brainstorming`
   - approved spec / frozen requirement -> `writing-plans`
   - start of implementation needing isolation -> `using-git-worktrees`
   - plan execution with subagents -> `subagent-driven-development`
   - plan execution without that mode -> `executing-plans`
   - feature or bugfix code -> `test-driven-development`
   - runtime failure / regression / unexpected behavior -> `systematic-debugging`
   - delivery review -> `requesting-code-review`
   - completion claim -> `verification-before-completion`
   - branch / worktree wrap-up -> `finishing-a-development-branch`

## Fallback Agent Roles

### `explorer`
- Use for read-only repository discovery, evidence gathering, and path tracing.

### `architect`
- Use for boundaries, interfaces, migration shape, and compatibility decisions.

### `reviewer`
- Use for correctness, regression, safety, and missing-test review.
