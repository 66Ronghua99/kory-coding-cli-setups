# Agent and Skill Index

This file is the routing table for the local Codex harness. `AGENTS.md` is the policy layer; this file is the execution map.

## Agent Roles

### `explorer`
- Use for repository scanning, code path tracing, dependency discovery, and evidence gathering.
- Read-only by default.
- Typical trigger:
  - "先看看现在代码怎么跑的"
  - "帮我探索一下这个仓库"
  - "先别改，先查清楚"

### `architect`
- Use for module boundaries, API contracts, migration plans, compatibility strategy, and system design tradeoffs.
- Read-only by default.
- Typical trigger:
  - cross-module refactor
  - shared contract change
  - public config/protocol change

### `reviewer`
- Use after code changes or before merge.
- Focus on bugs, regressions, security, missing tests, and maintainability risks.
- Read-only by default.

## Skill Routing

### `syncdoc`
- Use when `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, or `.plan/` are missing or out of sync.

### `pm-progress-requirement-discovery`
- Use only for requirement freeze.
- Output should define:
  - problem
  - scope
  - non-goals
  - acceptance criteria
  - open risks
- Do not use it to produce implementation steps.

### `drive-pm-closed-loop`
- Use only after requirement freeze.
- Output should define:
  - one minimum executable loop
  - verification steps
  - deferred scope
  - one `p0_next`

### `architecture-review`
- Use when requirements are frozen but implementation structure is still unclear.
- Especially relevant for cross-module changes or new shared contracts.

### `verification-loop`
- Use after implementation or before handoff.
- Run build/type/test/review evidence checks and summarize release readiness.

## Standard Route

1. Missing docs or drift:
   - `syncdoc`
2. Scope unclear:
   - `pm-progress-requirement-discovery`
3. Scope frozen but implementation path unclear:
   - `explorer` then `architecture-review` or `architect`
4. Ready to define one buildable slice:
   - `drive-pm-closed-loop`
5. Code written:
   - `reviewer`
6. Before delivery:
   - `verification-loop`

## PM Boundary Rule

- `pm-progress-requirement-discovery` owns requirement clarity.
- `drive-pm-closed-loop` owns execution compression.
- If requirement ambiguity remains, do not skip directly to closed-loop planning.
