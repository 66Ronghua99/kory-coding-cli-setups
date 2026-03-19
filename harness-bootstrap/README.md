# Harness Bootstrap Pack

Local asset source for bootstrapping repositories into a Superpowers-based Harness workflow.

## Purpose

This pack keeps repository bootstrap consistent across greenfield and migration scenarios.
`harness:init` should act as the controller. This directory stores the reusable files that the skill applies.

## Layout

- `skeleton/`: stack-agnostic repository baseline
- `presets/`: optional stack overlays
- `scripts/`: bootstrap and validation helpers

## Operating Model

1. Detect project mode.
2. Apply `greenfield` or `migration`.
3. Materialize `.harness/bootstrap.toml`.
4. Continue into spec and planning through Superpowers.

## Notes

- The first version defaults to the `none` preset.
- Template usage is enforced at the repository level, not by chat memory.
- The skeleton now materializes a default `docs_health_command`; stack-specific `verify_command` and `e2e_command` stay empty until the repository declares them.
