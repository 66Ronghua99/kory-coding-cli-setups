# Progress

## 2026-06-08

- Reframed the user-level collaboration model around `AGENTS.md`, `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, and `docs/superpowers/templates/`.
- Completed the light-init rewrite captured in:
  `docs/superpowers/specs/2026-06-08-user-level-light-init-spec.md`
  `docs/superpowers/plans/2026-06-08-user-level-light-init-implementation.md`
- Removed `.harness`, `AGENT_INDEX.md`, `PROJECT_LOGS.md`, and manifest-based truth from user-level bootstrap expectations while preserving Superpowers templates and the pointer-only `NEXT_STEP.md` rule.
- Verified the new contract by clearing old bootstrap references with `rg` and running `bash harness-bootstrap/scripts/validate_bootstrap.sh /Users/cory/.coding-cli`.
- Started the follow-up sync-agent-links rewrite for curated top-level `superpowers` skill exports and direct Codex skill links in:
  `docs/superpowers/specs/2026-06-08-sync-selected-superpowers-links-spec.md`
  `docs/superpowers/plans/2026-06-08-sync-selected-superpowers-links-implementation.md`
- Bash verification for the curated sync model now passes via `bash tests/sync-agent-links/test-sync-agent-links.sh`.
- PowerShell verification is still a local environment gap because `pwsh` is not installed in this macOS workspace.
