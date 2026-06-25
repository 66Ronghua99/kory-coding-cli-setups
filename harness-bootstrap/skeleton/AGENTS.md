# AGENTS.md

> Repository guide. This file is the map, not the encyclopedia.

## Read First

1. `NEXT_STEP.md`
2. `MEMORY.md`
3. `PROGRESS.md` (if the current state is unclear)

## Core Paths

- `docs/project/`: project-level context
- `docs/superpowers/templates/`: required document templates

## Rules

- Prefer repository-local documents over chat-only context.
- Use the matching Superpowers skill before implementation.
- `Superpowers` drives workflow execution; `Harness` defines lightweight governance standards.
- `Harness` enters the workflow for bootstrap and repository-truth questions; otherwise it stays as a constraint source behind the active Superpowers stage.
- Use `harness:doc-health` for repository truth, pointer drift, or stale spec/plan/evidence links.
- Create specs from `docs/superpowers/templates/SPEC_TEMPLATE.md`.
- Create plans from `docs/superpowers/templates/PLAN_TEMPLATE.md`.
- Keep `NEXT_STEP.md` to one direct pointer, or clear it when no next task exists.
- Do not claim completion without fresh verification evidence.
