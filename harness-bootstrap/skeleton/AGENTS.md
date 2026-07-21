# AGENTS.md

> Repository guide. Keep this file a map, not an encyclopedia.

## Read First

1. `NEXT_STEP.md`
2. `MEMORY.md`
3. `PROGRESS.md` when the current state is unclear
4. The active spec/plan/checklist referenced by `NEXT_STEP.md`

## Core Paths

- `docs/project/`: project-level context and document index
- `docs/superpowers/templates/`: spec, plan, change-request, and evidence templates
- `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, `docs/superpowers/`, and `artifacts/`: local-only collaboration state

## Rules

- Prefer repository-local evidence over chat-only assumptions.
- Reuse existing project conventions and verification commands.
- Use `brainstorming` for requirement/design work and `writing-plans` after the design is approved.
- Create specs and plans under `docs/superpowers/`; do not stage, commit, or push them.
- Keep `NEXT_STEP.md` to one direct pointer, or clear it when no next task exists.
- Fix root causes, keep scope minimal, and do not add unrequested fallback paths or abstractions.
- Do not claim completion without fresh test, smoke, or runtime evidence.
- Update local collaboration state only when repository truth changes.
