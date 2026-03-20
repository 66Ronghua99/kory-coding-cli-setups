---
name: harness:init
description: Use when entering a repository that needs the Harness governance baseline, project indexes, bootstrap manifest, and templates before design or implementation work begins.
---

# harness:init

Bootstrap a repository into the governance-only Harness model.

`harness:init` is the only Harness skill that remains executable. Its job is infrastructure setup only: establish the repository map, project context docs, bootstrap manifest, and Superpowers templates. It must not copy or vendor non-init Harness runtimes into the target repository.

## Entry Model

`harness:init` is the single user-facing bootstrap entrypoint.

It should:

1. detect whether the target directory is `greenfield` or `migration`
2. load the local bootstrap pack from `$HARNESS_CLI_HOME/harness-bootstrap` (fallback: `$CODEX_HOME/harness-bootstrap`, then `$HOME/.coding-cli/harness-bootstrap`)
3. apply the correct bootstrap script
4. materialize `.harness/bootstrap.toml`
5. leave `NEXT_STEP.md` pointing at spec creation through Superpowers

The intended user instruction is always:

- `Use harness:init to initialize this project`

## What Bootstrap Creates

After bootstrap, the repository should have:

- root governance docs: `AGENTS.md`, `AGENT_INDEX.md`, `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`
- bootstrap manifest: `.harness/bootstrap.toml`
- project context docs under `docs/project/`, `docs/architecture/`, and `docs/testing/`
- Superpowers templates under `docs/superpowers/templates/`

Bootstrap standardizes repository structure. It does not claim that the repository already has runnable doc-health, lint, or test gates.

## Mode Selection

### Greenfield

Use when the directory is empty or nearly empty.

Expected result:

- governance skeleton copied into the repository
- `.harness/bootstrap.toml` created from the example
- templates available under `docs/superpowers/templates/`
- `NEXT_STEP.md` points to spec creation

### Migration

Use when the directory already contains code or framework markers.

Expected result:

- missing Harness files added without overwriting product code
- `.harness/bootstrap.toml` created if missing
- `docs/project/current-state.md` written when missing
- repository state is ready for a migration audit or first spec

Migration is additive by default, not destructive.

## Manifest Rule

If `.harness/bootstrap.toml` exists, treat it as the bootstrap source of truth for:

- mode
- preset
- governance model
- templates directory
- active governance skills

Default values for the current model:

- `preset = "none"`
- `entry_skill = "harness:init"`
- `governance_model = "harness-governance-only.v1"`
- `doc_health_skill = "harness:doc-health"`
- `lint_test_skill = "harness:lint-test-design"`

The `mode` should be set from detection, not guessed from chat.

## Superpowers Integration

After bootstrap:

- `brainstorming` creates specs from `docs/superpowers/templates/SPEC_TEMPLATE.md`
- `writing-plans` creates plans from `docs/superpowers/templates/PLAN_TEMPLATE.md`
- scope changes use `docs/superpowers/templates/CHANGE_REQUEST_TEMPLATE.md`
- delivery evidence uses `docs/superpowers/templates/EVIDENCE_TEMPLATE.md`
- `harness:doc-health` and `harness:lint-test-design` provide the governance standards agents must read during those workflows

`harness:init` does not replace Superpowers. It only prepares the repository so Superpowers can run against a stable, documented baseline.

## Guardrails

- Do not guess the repository mode if the detection script can answer it.
- Do not invent stack presets. Default to `none` unless a real preset exists.
- Do not overwrite product code during migration.
- Do not vendor non-init Harness skills into any repository-local runtime directory.
- Do not leave placeholder execution commands in the manifest that imply automation which no longer exists.
- Do not stop at file creation only; leave a clear next action in `NEXT_STEP.md`.
- Do not bake machine-specific absolute paths into scripts or generated project docs.

## Reference Pack

- `references/bootstrap-manifest-spec.md`
- `references/repository-minimum.md`
- `references/superpowers-integration-map.md`
- `checklists/greenfield-bootstrap.md`
- `checklists/migration-bootstrap.md`
- `examples/greenfield-after.md`
- `examples/migration-after.md`
