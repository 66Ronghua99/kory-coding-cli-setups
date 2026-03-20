# Agent Index

## Default Route

1. Load `using-superpowers`.
2. Read `PROGRESS.md`, `NEXT_STEP.md`, `MEMORY.md`, and `.harness/bootstrap.toml`.
3. Route by task type:
   - new workflow or behavior design -> `brainstorming`
   - approved multi-step work -> `writing-plans`
   - implementation in this session -> `executing-plans` or `subagent-driven-development`
   - feature or bugfix coding -> `test-driven-development`
   - runtime failure or regression -> `systematic-debugging`
   - repository truth, pointer drift, or stale spec/plan/evidence links -> `harness:doc-health`
   - code invariant, lint boundary, or test-boundary design -> `harness:lint-test-design`
   - delivery review -> `requesting-code-review`
   - completion claim -> `verification-before-completion`

## Bootstrap Rule

If `.harness/bootstrap.toml` exists, treat it as the machine-readable bootstrap source of truth.
