# Memory

## Stable Notes

- This repository was initialized from the minimal Harness documentation pack.
- Bootstrap output is limited to `AGENTS.md`, `.gitignore`, `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, `docs/project/README.md`, and `docs/superpowers/templates/`.
- Templates under `docs/superpowers/templates/` define the local spec, plan, change-request, and evidence shapes.
- `.gitignore` keeps `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, `docs/superpowers/`, `artifacts/`, and generated root Markdown local while allowing project `AGENTS.md` and root `README.md`.
- `brainstorming` owns requirement/design work; `writing-plans` owns approved implementation breakdowns.

## Working Heuristics

- Keep repository-local docs aligned with current code and verification evidence.
- Record reusable root-cause, fix, and prevention boundaries here; do not append session流水.
- Prefer explicit failure semantics over silent fallback behavior.
- Keep one active next-step pointer and remove stale pointers when a loop closes.
