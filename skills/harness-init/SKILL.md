---
name: harness:init
description: Initialize a repository into the local Harness workflow using one entrypoint, a local bootstrap pack, and greenfield or migration mode depending on the current directory.
---

# harness:init

Use the local bootstrap pack to bring a repository into the same Harness workflow, regardless of whether the target is brand new or already contains code.

## Entry Model

`harness:init` is the single user-facing entrypoint.

It should:

1. detect whether the target directory is `greenfield` or `migration`
2. load the local bootstrap pack from `~/.coding-cli/harness-bootstrap`
3. apply the correct bootstrap script
4. materialize `.harness/bootstrap.toml`
5. stop on a clear next action

The intended user instruction is always:

- `Use harness:init to initialize this project`

## Local Asset Source

Use these local paths:

- Pack root: `/Users/cory/.coding-cli/harness-bootstrap`
- Detection script: `/Users/cory/.coding-cli/harness-bootstrap/scripts/detect_project_mode.sh`
- Greenfield script: `/Users/cory/.coding-cli/harness-bootstrap/scripts/bootstrap_greenfield.sh`
- Migration script: `/Users/cory/.coding-cli/harness-bootstrap/scripts/bootstrap_migration.sh`
- Preset script: `/Users/cory/.coding-cli/harness-bootstrap/scripts/apply_preset.sh`
- Validation script: `/Users/cory/.coding-cli/harness-bootstrap/scripts/validate_bootstrap.sh`

## Mode Selection

### Greenfield

Use when the directory is empty or nearly empty.

Expected result:

- governance skeleton copied into the repository
- `.harness/bootstrap.toml` created from the example
- template directory available under `docs/superpowers/templates/`
- `NEXT_STEP.md` points to spec creation

### Migration

Use when the directory already contains code or framework markers.

Expected result:

- missing Harness files added without overwriting product code
- `.harness/bootstrap.toml` created if missing
- `docs/project/current-state.md` written when missing
- repository state is ready for a migration audit or first spec

Migration is additive by default, not destructive.

## Required Repository Assets

After bootstrap, these files should exist:

- `AGENTS.md`
- `AGENT_INDEX.md`
- `PROGRESS.md`
- `MEMORY.md`
- `NEXT_STEP.md`
- `.harness/bootstrap.toml`
- `docs/project/README.md`
- `docs/architecture/overview.md`
- `docs/architecture/layers.md`
- `docs/testing/strategy.md`
- `docs/superpowers/templates/SPEC_TEMPLATE.md`
- `docs/superpowers/templates/PLAN_TEMPLATE.md`
- `docs/superpowers/templates/CHANGE_REQUEST_TEMPLATE.md`
- `docs/superpowers/templates/EVIDENCE_TEMPLATE.md`

## Manifest Rule

If `.harness/bootstrap.toml` exists, treat it as the bootstrap source of truth for:

- mode
- preset
- templates directory
- docs health command
- verification command
- e2e command

Default values for the first version:

- `preset = "none"`
- `entry_skill = "harness:init"`

The `mode` should be set from detection, not guessed from chat.

## Superpowers Integration

After bootstrap:

- `brainstorming` should create specs from `docs/superpowers/templates/SPEC_TEMPLATE.md`
- `writing-plans` should create plans from `docs/superpowers/templates/PLAN_TEMPLATE.md`
- scope changes should be classified through `docs/superpowers/templates/CHANGE_REQUEST_TEMPLATE.md`
- delivery evidence should use `docs/superpowers/templates/EVIDENCE_TEMPLATE.md`

`harness:init` does not replace the normal Superpowers workflow. It standardizes the repository starting point and artifact layout.

## Guardrails

- Do not guess the repository mode if the detection script can answer it.
- Do not invent stack presets. Default to `none` unless a real preset exists.
- Do not overwrite product code during migration.
- Do not stop at file creation only; leave a clear next action in `NEXT_STEP.md`.
- Do not rely on chat memory when the bootstrap manifest or repository docs already describe the setup.

## Success Criteria

- one skill invocation can initialize a brand-new repository
- one skill invocation can sync a legacy repository into the Harness workflow
- future agents can read `.harness/bootstrap.toml` instead of inferring setup details
- bootstrapped repositories continue naturally into spec, plan, implementation, and verification
