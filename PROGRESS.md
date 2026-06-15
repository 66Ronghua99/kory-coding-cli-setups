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
- Added the Humanize RLCR sync loop captured in:
  `docs/superpowers/specs/2026-06-08-humanize-rlcr-sync-spec.md`
  `docs/superpowers/plans/2026-06-08-humanize-rlcr-sync-implementation.md`
- `sync-agent-links.sh` now manages a root-level ignored `humanize/` checkout and invokes `humanize/scripts/install-skill.sh --target codex` so Codex RLCR skills/runtime/hooks are installed during environment sync.
- `sync-agent-links.ps1` mirrors the Humanize checkout/install path and explicitly requires `bash` for the Humanize installer unless `HUMANIZE_SYNC=0`.
- Verified Humanize sync behavior with `bash tests/sync-agent-links/test-sync-agent-links.sh` and `./sync-agent-links.sh --dry-run`; `pwsh` remains unavailable locally, so PowerShell execution is still a verification gap.

## 2026-06-15

- Adapted `skills/grill-with-docs/SKILL.md` from a DDD glossary/ADR grilling workflow into a Superpowers spec-hardening workflow aligned with `NEXT_STEP.md`, `MEMORY.md`, active specs, active plans, and the lightweight project document spine.
- Preserved `CONTEXT-FORMAT.md` and `ADR-FORMAT.md` as optional compatibility references, but changed the default flow so `CONTEXT.md` and ADRs are not created unless the project already uses them or the user explicitly asks.
- Verified the skill structure with `python3 /Users/cory/.codex/skills/.system/skill-creator/scripts/quick_validate.py /Users/cory/.coding-cli/skills/grill-with-docs`.
