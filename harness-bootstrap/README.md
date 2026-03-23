# Harness Bootstrap Pack

Local asset source for bootstrapping repositories into a governance-only Harness workflow.

## Purpose

This pack keeps repository bootstrap consistent across greenfield and migration scenarios.
`harness:init` acts as the controller. This directory stores the reusable files and scripts that initialize repository structure, index docs, and templates.

## Layout

- `skeleton/`: stack-agnostic repository baseline
- `presets/`: optional stack overlays
- `scripts/`: bootstrap and validation helpers

## Operating Model

1. Detect project mode.
2. Apply `greenfield` or `migration`.
3. Materialize `.harness/bootstrap.toml`.
4. Create repository context docs and Superpowers templates.
5. Continue into spec and planning through Superpowers.

## Notes

- The current model is `harness-governance-only.v1`.
- The first version defaults to the `none` preset.
- Template usage is enforced at the repository level, not by chat memory.
- The bootstrap manifest describes structure and active governance skills, not executable runtime commands.
- Runtime source resolution defaults to `$HARNESS_CLI_HOME`, then `$CODEX_HOME`, then `$HOME/.coding-cli`.
- Repositories may declare a local commit-time `harness:refactor` gate in `.harness/bootstrap.toml`.
- The shared `harness:refactor` skill remains governance-only; local hooks only validate fresh gate evidence for the current staged snapshot.
- Skeleton assets may include `.githooks/` and `.gitignore` examples for local refactor-gate enforcement.
- Reusable installer ownership for local hooks is still deferred and may later move into `harness:develop`.
