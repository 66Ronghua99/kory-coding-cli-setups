---
name: harness:init
description: Users only proactively use this when entering a repository that needs the minimal collaboration baseline and Superpowers templates before design or implementation work begins.
---

# harness:init

Bootstrap a repository into the lightweight Harness collaboration model.

`harness:init` is the only Harness skill that remains executable. Its job is infrastructure setup only: establish the minimum collaboration docs, project-level docs, Superpowers templates, and target-project `.gitignore` entries for generated Harness docs. It must not copy or vendor non-init Harness runtimes, local hooks, preset manifests, broad gitignore examples, or stack-specific generated docs into the target repository.

## Entry Model

`harness:init` is the single user-facing bootstrap entrypoint.

It should:

1. detect whether the target directory is `greenfield` or `migration`
2. load the local bootstrap pack from `$HARNESS_CLI_HOME/harness-bootstrap` (fallback: `$CODEX_HOME/harness-bootstrap`, then `$HOME/.coding-cli/harness-bootstrap`)
3. apply the correct bootstrap script
4. leave `NEXT_STEP.md` pointing at the first spec or plan entrypoint through Superpowers

The intended user instruction is always:

- `Use harness:init to initialize this project`

## What Bootstrap Creates

After bootstrap, the repository should have:

- root collaboration docs: `AGENTS.md`, `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`
- project-level docs under `docs/project/`
- Superpowers templates under `docs/superpowers/templates/`
- target project `.gitignore` entries that ignore `docs/superpowers/`, `artifacts/`, and project-root `*.md`, while keeping `AGENTS.md` and root `README.md` trackable

Bootstrap standardizes the collaboration entrypoint. It does not claim that the repository already has runnable doc-health, lint, or test gates.

## Mode Selection

### Greenfield

Use when the directory is empty or nearly empty.

Expected result:

- governance skeleton copied into the repository
- templates available under `docs/superpowers/templates/`
- `NEXT_STEP.md` points to spec creation

### Migration

Use when the directory already contains code or framework markers.

Expected result:

- missing Harness files added without overwriting product code
- repository state is ready for a migration audit or first spec

Migration is additive by default, not destructive.

## Superpowers Integration

After bootstrap:

- `brainstorming` creates specs from `docs/superpowers/templates/SPEC_TEMPLATE.md`
- `writing-plans` creates plans from `docs/superpowers/templates/PLAN_TEMPLATE.md`
- scope changes use `docs/superpowers/templates/CHANGE_REQUEST_TEMPLATE.md`
- delivery evidence uses `docs/superpowers/templates/EVIDENCE_TEMPLATE.md`
- `harness:doc-health` provides the governance standards agents must read during repository truth and pointer-drift workflows

`harness:init` does not replace Superpowers. It only prepares the repository so Superpowers can run against a stable, documented baseline.

## Recovery Model

The lightweight baseline assumes:

- `NEXT_STEP.md` is a pointer-only file that references the active spec, plan, or checklist
- `PROGRESS.md` stores cumulative execution summaries and is optional to read on every turn
- `MEMORY.md` stores stable lessons and should not become a running log
- if state is unclear, agents recover it from `NEXT_STEP.md`, current spec/plan/checklist status, and bounded code review

## Guardrails

- Do not guess the repository mode if the detection script can answer it.
- Do not overwrite product code during migration.
- Do not vendor non-init Harness skills into any repository-local runtime directory.
- Do not add local hooks, pre-commit files, preset manifests, broad gitignore examples, or stack-specific context docs beyond the minimal `docs/project/README.md` during bootstrap.
- Only update the target project `.gitignore` for the Harness-generated docs/evidence contract: ignore `docs/superpowers/`, `artifacts/`, and project-root `*.md`, then unignore project-level `AGENTS.md` and root `README.md`.
- Do not stop at file creation only; leave a clear next action in `NEXT_STEP.md`.
- Do not bake machine-specific absolute paths into scripts or generated project docs.
- Do not reintroduce hidden manifest-based truth for user-level bootstrap.
- At goal completion, perform a file-state review so `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, and active spec/plan/checklist truth remain aligned.

## Reference Pack

- `references/repository-minimum.md`
- `references/superpowers-integration-map.md`
- `checklists/greenfield-bootstrap.md`
- `checklists/migration-bootstrap.md`
- `examples/greenfield-after.md`
- `examples/migration-after.md`
