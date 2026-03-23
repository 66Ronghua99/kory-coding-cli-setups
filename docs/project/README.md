# Project Context

## Purpose

This repository is the user's shared coding-agent control plane. It stores the common instructions, local skills, Harness governance assets, and sync scripts that project those files into agent-specific homes such as `.claude`, `.gemini`, `.copilot`, and `.codex`.

## Success Criteria

- A fresh machine can run one sync command and receive the expected agent config, skills, and governance files.
- `superpowers` is versioned as a Git submodule and can be fetched with the parent repository through recursive clone or submodule init/update commands.
- The downstream agent homes stay consistent with the repository source of truth through symlinks or junctions rather than copied snapshots.

## Constraints

- Prefer explicit failure over silent fallback when git state, link targets, or update conditions are invalid.
- Preserve the existing whole-directory `skills` sync model so current agent discovery behavior does not regress.
- Windows support should follow hidden-directory conventions under `%USERPROFILE%`.
- `skills/superpowers` is a generated local link target and must stay out of Git tracking.

## Git Setup

- Clone fresh with `git clone --recurse-submodules <repo>`.
- In an existing clone, run `git submodule update --init --recursive`.
- Update `superpowers` manually when needed with `git submodule update --remote superpowers`.
- Run the sync script after submodule init or update so it can recreate `skills/superpowers -> superpowers/skills`.

## Related Docs

- `docs/architecture/overview.md`
- `docs/testing/strategy.md`
- `docs/superpowers/templates/SPEC_TEMPLATE.md`
- `docs/superpowers/specs/2026-03-23-cross-platform-sync-and-superpowers-bootstrap-design.md`
- `docs/superpowers/plans/2026-03-23-cross-platform-sync-and-superpowers-bootstrap-implementation.md`
