---
name: pm-progress-requirement-discovery
description: Freeze requirements before planning or coding by extracting scope, non-goals, acceptance criteria, and blocking unknowns from current project progress.
---

# PM Requirement Freeze

## Goal

Turn project status into an explicit requirement snapshot before any closed-loop planning or implementation starts.

This skill reduces uncertainty. It does not design the implementation.

## Workflow

### 1) Build Evidence Context

Read files in this order:
1. `PROGRESS.md`
2. `NEXT_STEP.md`
3. `MEMORY.md`
4. active `.plan/*.md` requirement or design doc
5. `AGENT_INDEX.md`

If a file is missing, state the gap explicitly and continue with available evidence.

### 2) Build Requirement Delta Map

Extract and separate:
- `Known`: business goal, user outcome, hard constraints, existing assumptions
- `Unknown`: missing facts that block requirement freeze
- `Conflicts`: contradictions between milestone, next step, and prior notes

### 3) Generate PM Clarification Questions

Generate questions across these dimensions:
- Business outcome and success metric
- Target users and usage boundaries
- Workflow/path definition
- Acceptance evidence and quality bar
- Risk, dependency, and rollout constraints

Question requirements:
- Ask only the necessary questions to freeze scope.
- Prioritize `P0` blockers first.
- Keep one question focused on one decision.
- Attach a short `Why this matters` note to every question.
- Mark priority: `P0` (blocking), `P1` (important), `P2` (optimization).

### 4) Prioritize for Decision Impact

Order questions by:
1. Blockers for next implementation step
2. Risks that can invalidate current milestone
3. Questions that affect acceptance criteria or testability

Do not propose file-level implementation steps, architecture changes, or execution phases here.

### 5) Converge Requirement Snapshot

After answers are available, produce requirement `v0` with:
- Problem
- Scope
- Non-goals
- Acceptance criteria
- Evidence artifacts
- Outstanding risks and unknowns

## Output Contract

Return sections in this exact order:
1. `Project Reading Snapshot`
2. `Requirement Gaps (Known/Unknown/Conflicts)`
3. `Critical Questions (P0/P1/P2)`
4. `Requirement Snapshot v0`
5. `Next Confirmation Checklist`

For `Critical Questions`, use a table with columns:
- `ID`
- `Priority`
- `Question`
- `Why this matters`
- `Decision unlocked after answer`

## Rules

- Use the user's language.
- Ground every question in project evidence; avoid generic PM boilerplate.
- Challenge ambiguous statements and convert them into deterministic choices.
- When data is missing, ask instead of guessing.
- Do not produce implementation steps, migration plans, or task breakdowns.
- Hand off to `drive-pm-closed-loop` only after the requirement snapshot is stable.

## Cross-Skill Handoff (with `syncdoc` and `drive-pm-closed-loop`)

### Upstream Expectation
- Prefer running `syncdoc` first to ensure `PROGRESS/MEMORY/NEXT_STEP/.plan` are structurally valid.

### This Skill Must Produce
- A requirement snapshot that can be consumed by `drive-pm-closed-loop` without more requirement discovery.
- Suggested persistence path:
  - `.plan/{YYYYMMDD}_{feature}_requirement_v0.md`

### Required Handoff Fields
- `feature_name`
- `stage_name`
- `problem`
- `scope`
- `non_goals`
- `acceptance_criteria`
- `evidence_artifacts`
- `open_risks`
- `p0_next_candidate`

### Downstream Hand-off Rule
- After user confirms Requirement v0, hand off to `drive-pm-closed-loop` to freeze one minimum executable loop.
- Do not output roadmap expansion or implementation sequencing before `P0` blockers are answered.
