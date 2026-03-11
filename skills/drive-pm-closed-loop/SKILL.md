---
name: drive-pm-closed-loop
description: Compress a frozen requirement into one executable and verifiable minimum closed loop with explicit acceptance checks, deferred scope, and a single next action.
---

# Drive PM Closed Loop

## Goal

Convert a frozen requirement into:
- One executable minimum closed loop
- Testable acceptance criteria
- A prioritized next-iteration plan

## Run Workflow

1. Validate requirement freeze
- Read the requirement snapshot first.
- If problem, scope, non-goals, or acceptance criteria are still ambiguous, stop and return to `pm-progress-requirement-discovery`.

2. Freeze one minimum closed loop
- Keep scope to one user journey and one measurable outcome.
- Reject "build everything first" requests and force a smallest valuable loop.
- Define the minimum slice that can be executed and verified.

3. Write executable requirements
- Define scope and non-goals explicitly.
- Translate ambiguous statements into deterministic rules and acceptance criteria.
- Name what is intentionally deferred.

4. Define verification plan
- Specify how to verify behavior (manual checkpoints or automated tests).
- Require observable evidence for each acceptance criterion (logs, screenshots, artifacts, metrics).
- Define pass and fail thresholds.

5. Plan the next iteration
- Load `references/iteration-template.md`.
- Prioritize backlog by impact, confidence, and effort.
- Output only 1-3 highest-value next actions.

## Enforce PM Rules

- Clarify before committing: list missing facts and assumptions first.
- Close one loop before expansion: do not expand roadmap before minimum loop is verifiable.
- Make outcomes measurable: every goal must map to an observable signal.
- Keep tradeoffs explicit: explain what is intentionally deferred.
- Do not reopen requirement discovery unless the requirement snapshot is incomplete or contradictory.

## Use Output Contract

Always return these sections in order:

1. `Requirement Summary`
2. `Minimum Closed Loop Definition`
3. `Verification Plan`
4. `Next Iteration Plan`

If information is incomplete, keep the same sections and mark assumptions inline.

## Cross-Skill Handoff (with `pm-progress-requirement-discovery` and `syncdoc`)

### Upstream Expectation
- Input should come from confirmed requirement snapshot (typically from `pm-progress-requirement-discovery`).
- If requirement is not frozen, stop and ask for missing requirement fields first.

### This Skill Must Produce
- One minimum executable loop with deterministic acceptance checks.
- Suggested persistence paths:
  - `.plan/{YYYYMMDD}_{feature}_closed_loop_v0.md`
  - `.plan/checklist_{feature}_closed_loop_v0.md`

### Required Output Fields
- `feature_name`
- `stage_name`
- `requirement_source`
- `minimum_loop_scope`
- `acceptance_criteria`
- `verification_steps`
- `evidence_paths`
- `deferred_scope`
- `p0_next`

### Downstream Hand-off Rule
- After loop definition is confirmed, run `syncdoc` to sync:
  - `PROGRESS.md` TODO/DONE and milestone
  - `NEXT_STEP.md` single pointer (must equal `p0_next`)
  - `MEMORY.md` reusable constraints/lessons if any
