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
- Treat `.harness/bootstrap.toml` as the machine-readable bootstrap source of truth.
- `Superpowers` drives workflow execution; `Harness` defines governance standards.
- `Harness` enters the workflow when bootstrap, repository truth, invariant design, or architecture-drift questions appear; otherwise it stays as a constraint source behind the active Superpowers stage.
- Use `harness:doc-health` for repository truth, pointer drift, or stale spec/plan/evidence links.
- Use `harness:lint-test-design` for lint/test invariant design and hardgate policy.
- Use `harness:refactor` for architecture-drift findings and bounded refactor governance.
- Create specs from `docs/superpowers/templates/SPEC_TEMPLATE.md`.
- Create plans from `docs/superpowers/templates/PLAN_TEMPLATE.md`.
- Keep `NEXT_STEP.md` to one direct next action.
- Do not claim completion without fresh verification evidence.
