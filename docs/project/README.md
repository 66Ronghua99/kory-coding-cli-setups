# Project Context

## Purpose

This repository is the user's shared coding-agent control plane. It stores the common instructions, local skills, Harness governance assets, and sync scripts that project those files into agent-specific homes such as `.claude`, `.gemini`, `.copilot`, and `.codex`.

## Success Criteria

- A fresh machine can run one sync command and receive the expected agent config, skills, and governance files.
- `superpowers` is treated as a managed dependency of the sync flow instead of a manual after-step.
- The downstream agent homes stay consistent with the repository source of truth through symlinks or junctions rather than copied snapshots.

## Constraints

- Prefer explicit failure over silent fallback when git state, link targets, or update conditions are invalid.
- Preserve the existing whole-directory `skills` sync model so current agent discovery behavior does not regress.
- Windows support should follow hidden-directory conventions under `%USERPROFILE%`.

## Related Docs

- `docs/architecture/overview.md`
- `docs/testing/strategy.md`
- `docs/superpowers/templates/SPEC_TEMPLATE.md`
- `docs/superpowers/specs/2026-03-23-cross-platform-sync-and-superpowers-bootstrap-design.md`
- `docs/superpowers/plans/2026-03-23-cross-platform-sync-and-superpowers-bootstrap-implementation.md`
