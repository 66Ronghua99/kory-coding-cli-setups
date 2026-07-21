---
name: harness:init
description: Initialize only the minimal project collaboration documents and Superpowers templates when the user explicitly asks to prepare a repository for agent work.
---

# harness:init

Initialize a repository's documentation baseline. This skill is an explicit setup action, not a mandatory precondition for ordinary coding tasks.

## Entry

Use only when the user asks to initialize or repair the project's collaboration-document skeleton:

- `Use harness:init to initialize this project`

Load the bootstrap pack from `$HARNESS_CLI_HOME/harness-bootstrap`, falling back to `$CODEX_HOME/harness-bootstrap`, then `$HOME/.coding-cli/harness-bootstrap`.

## Allowed Output

Bootstrap may create or maintain only:

```text
AGENTS.md
PROGRESS.md
MEMORY.md
NEXT_STEP.md
docs/project/README.md
docs/superpowers/templates/SPEC_TEMPLATE.md
docs/superpowers/templates/PLAN_TEMPLATE.md
docs/superpowers/templates/CHANGE_REQUEST_TEMPLATE.md
docs/superpowers/templates/EVIDENCE_TEMPLATE.md
.gitignore entries required by this document contract
```

The `.gitignore` contract is:

- ignore `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, `docs/superpowers/`, `artifacts/`, and other generated root Markdown;
- keep project `AGENTS.md` and root `README.md` trackable;
- if local-only paths are already tracked during migration, remove them from the Git index without deleting working-tree files.

## Modes

### Greenfield

Use for an empty or nearly empty target. Copy the minimal documents and templates, then point `NEXT_STEP.md` at the first spec entrypoint.

### Migration

Use for a repository that already contains code or framework markers. Add missing baseline files without overwriting product code or established project documentation.

Mode detection must come from the bootstrap script; do not guess when detection is available.

## Document Responsibilities

- `AGENTS.md`: static project map, boundaries, and verification entrypoints.
- `PROGRESS.md`: concise cumulative execution conclusions.
- `MEMORY.md`: reusable lessons and stable constraints.
- `NEXT_STEP.md`: one active spec/plan/checklist pointer.
- `docs/project/README.md`: minimal project-document index.
- `docs/superpowers/templates/`: spec, plan, change-request, and evidence shapes.

`PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, `docs/superpowers/`, and `artifacts/` remain local-only collaboration state.

## Prohibited Output

Do not create or install:

- executable runtime bundles;
- Git or agent event hooks;
- hidden manifests or preset TOML files;
- default architecture or testing trees;
- stack-specific generated documentation;
- repository-local copies of unrelated skills;
- broad example configuration unrelated to the allowed document set.

## Completion

- Validate the generated target with `harness-bootstrap/scripts/validate_bootstrap.sh <target>`.
- Confirm migration did not overwrite product files.
- Leave exactly one executable next action in `NEXT_STEP.md`.
