# Memory

## Stable Notes

- This repository was initialized from the local Harness bootstrap pack.
- Required bootstrap files are `AGENTS.md`, `.gitignore`, `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, plus `docs/superpowers/templates/`.
- Template files under `docs/superpowers/templates/` define the required document shape.
- `.gitignore` should keep generated Harness docs and evidence local by ignoring `docs/superpowers/`, `artifacts/`, and project-root `*.md`, while explicitly allowing project-level `AGENTS.md` and root `README.md`.
- Harness skills define governance standards; Superpowers drives workflow execution.
- `harness:doc-health` owns repository truth and pointer consistency.

## Working Heuristics

- Keep repository-local docs ahead of implementation drift.
- Encode repeated review feedback into templates, focused tests, documented follow-up tasks, or small cleanup plans.
- Prefer explicit failure semantics over silent fallback behavior.
- Route stale docs to `harness:doc-health`; use normal tests, review, and concrete follow-up tasks for implementation quality issues.
