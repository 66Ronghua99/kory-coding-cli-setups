# Progress

## 2026-06-08

- Reframed the user-level collaboration model around `AGENTS.md`, `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, and `docs/superpowers/templates/`.
- Completed the light-init rewrite captured in:
  `docs/superpowers/specs/2026-06-08-user-level-light-init-spec.md`
  `docs/superpowers/plans/2026-06-08-user-level-light-init-implementation.md`
- Removed `.harness`, `AGENT_INDEX.md`, `PROJECT_LOGS.md`, and manifest-based truth from user-level bootstrap expectations while preserving Superpowers templates and the pointer-only `NEXT_STEP.md` rule.
- Verified the new contract by clearing old bootstrap references with `rg` and running `bash harness-bootstrap/scripts/validate_bootstrap.sh /Users/cory/.coding-cli`.
