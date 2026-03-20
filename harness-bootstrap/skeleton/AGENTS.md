# AGENTS.md

> Repository guide. This file is the map, not the encyclopedia.

## Read First

1. `PROGRESS.md`
2. `NEXT_STEP.md`
3. `MEMORY.md`
4. `AGENT_INDEX.md`
5. `.harness/bootstrap.toml`

## Core Paths

- `docs/project/`: project context
- `docs/architecture/`: architecture map and rules
- `docs/testing/`: testing strategy and invariant notes
- `docs/superpowers/templates/`: required document templates
- `artifacts/`: evidence and validation outputs

## Rules

- Prefer repository-local documents over chat-only context.
- Use the matching Superpowers skill before implementation.
- Read Harness governance skills when checking repository truth or code invariants.
- Create specs from `docs/superpowers/templates/SPEC_TEMPLATE.md`.
- Create plans from `docs/superpowers/templates/PLAN_TEMPLATE.md`.
- Keep `NEXT_STEP.md` to one direct next action.
- Do not claim completion without fresh verification evidence.
