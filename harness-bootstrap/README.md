# Harness Bootstrap Pack

Local asset source for bootstrapping repositories into a lightweight Harness workflow.

## Purpose

This pack keeps repository bootstrap consistent across greenfield and migration scenarios.
`harness:init` acts as the controller. This directory stores the reusable files and scripts that initialize the minimal collaboration docs, project-level docs, and Superpowers templates.

## Layout

- `skeleton/`: stack-agnostic repository baseline
- `scripts/`: bootstrap and validation helpers

## Operating Model

1. Detect project mode.
2. Apply `greenfield` or `migration`.
3. Create collaboration docs, project-level docs, and Superpowers templates.
4. Update the target project's `.gitignore` so generated Harness docs stay local by default.
5. Leave `NEXT_STEP.md` pointing at spec/planning through Superpowers.

## Notes

- The current model is `harness-governance-only.v1`.
- Template usage is enforced at the repository level, not by chat memory.
- Runtime source resolution defaults to `$HARNESS_CLI_HOME`, then `$CODEX_HOME`, then `$HOME/.coding-cli`.
- Bootstrap intentionally avoids local hooks, preset manifests, broad gitignore examples, and stack-specific generated docs beyond the minimal `docs/project/README.md`.
- Bootstrap only adds target-project `.gitignore` entries for `docs/superpowers/`, `artifacts/`, project-root `*.md`, and the `AGENTS.md`/root `README.md` exceptions.
