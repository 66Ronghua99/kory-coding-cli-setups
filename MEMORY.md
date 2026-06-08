# Memory

## Stable Notes

- This repository was initialized from the local Harness bootstrap pack.
- User-level bootstrap is intentionally lightweight: required collaboration files are `AGENTS.md`, `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, plus `docs/superpowers/templates/`.
- Template files under `docs/superpowers/templates/` define the required document shape.
- Harness skills define governance standards; Superpowers drives workflow execution.
- `harness:doc-health` owns repository truth and pointer consistency.
- `harness:lint-test-design` owns lint/test invariant and hardgate design.
- `harness:refactor` owns architecture-drift review and refactor governance.
- `NEXT_STEP.md` is a pointer-only file; if no follow-up task exists after completion, it should be cleared instead of carrying stale prose.
- `PROGRESS.md` is an accumulating execution summary, not a mandatory read on every coding turn.
- The shared `skills` directory remains the downstream sync unit for agent homes; `superpowers` is exposed through a curated generated set of top-level links under [`skills/`](/Users/cory/.coding-cli/skills), not through a nested `skills/superpowers` namespace.
- `superpowers` sync is owned by [`sync-agent-links.sh`](/Users/cory/.coding-cli/sync-agent-links.sh) and [`sync-agent-links.ps1`](/Users/cory/.coding-cli/sync-agent-links.ps1): they clone or fast-forward the checkout and regenerate the curated top-level links as local, ignored artifacts.
- `sync-agent-links.sh` is the macOS/Linux source of truth for the target mapping, and [`sync-agent-links.ps1`](/Users/cory/.coding-cli/sync-agent-links.ps1) mirrors that behavior for Windows hidden directories under `%USERPROFILE%`.
- On Windows, `sync-agent-links.ps1` falls back to hard links for file targets like `CLAUDE.md`, `AGENTS.md`, and `config.toml` when symbolic-link privilege is unavailable; directory targets still fall back to junctions.
- Windows backup paths must be normalized under `.coding-cli-sync-backups/<timestamp>/<drive>/...`; appending raw absolute paths creates invalid or misleading backup destinations.

## Working Heuristics

- Keep repository-local docs ahead of implementation drift.
- Encode repeated review feedback into templates, lint, tests, or recurring refactor work.
- Prefer explicit failure semantics over silent fallback behavior.
- Route stale docs to `harness:doc-health`, enforceable recurring issues to `harness:lint-test-design`, and architecture erosion to `harness:refactor`.
- When state is unclear, recover truth from `NEXT_STEP.md`, current spec/plan/checklist completion, and bounded code review before editing progress summaries.
- Treat missing `pwsh` on macOS as a verification gap to document, not a reason to claim Windows execution was tested.
- When PowerShell runs native tools like `git` or `cmd`, check exit codes explicitly; non-zero native exits do not automatically become terminating errors.
