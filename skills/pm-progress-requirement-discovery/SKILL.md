---
name: pm-progress-requirement-discovery
description: Professional PM requirement-discovery interviewer that reads project progress artifacts and asks high-impact clarification questions to define current scope, acceptance criteria, and risks. Use when the user asks to clarify requirements, decide next priorities, identify unknowns from PROGRESS/TODO, or explicitly asks for many necessary PM questions before implementation.
---

# PM Progress Requirement Discovery

## Goal

Turn project status into explicit, executable requirements by asking the right questions first.
Prioritize uncertainty reduction over immediate solutioning.

## Workflow

### 1) Build Evidence Context

Read files in this order:
1. `PROGRESS.md`
2. `<cwd>/.plan/***_plan.md` (or latest `.plan/*.md` requirement doc)
3. `MEMORY.md`
4. `NEXT_STEP.md`

If a file is missing, refer to codes for current project states. State the gap explicitly and continue with available evidence.

### 2) Build Requirement Delta Map

Extract and separate:
- `Known`: goals, constraints, completed capabilities, fixed assumptions
- `Unknown`: missing facts that block requirement finalization
- `Conflicts`: contradictions between milestone, TODO, and acceptance criteria

### 3) Generate PM Clarification Questions

Load `references/question-catalog.md` and generate questions across these dimensions:
- Business outcome and success metric
- Target users and usage boundaries
- Workflow/path definition
- Acceptance evidence and quality bar
- Risk, dependency, and rollout constraints

Question requirements:
- Ask many necessary questions by default: `>=12` (target `15-25`).
- Keep one question focused on one decision.
- Attach a short `Why this matters` note to every question.
- Mark priority: `P0` (blocking), `P1` (important), `P2` (optimization).

### 4) Prioritize for Decision Impact

Order questions by:
1. Blockers for next implementation step
2. Risks that can invalidate current milestone
3. Questions that affect acceptance criteria or testability

Do not propose implementation details before P0 questions are answered.

### 5) Converge Requirement Snapshot

After user answers, load `references/requirement-canvas.md` and produce requirement `v0`:
- Scope
- Non-goals
- Acceptance criteria
- Evidence artifacts
- Outstanding risks/unknowns

## Output Contract

Return sections in this exact order:
1. `Project Reading Snapshot`
2. `Requirement Gaps (Known/Unknown/Conflicts)`
3. `Critical Questions (P0/P1/P2)`
4. `Provisional Requirement Draft`
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

## Progressive Loading

- Read `references/question-catalog.md` when building question sets.
- Read `references/requirement-canvas.md` when synthesizing answers into requirement v0.

## Cross-Skill Handoff (with `syncdoc` and `drive-pm-closed-loop`)

### Upstream Expectation
- Prefer running `syncdoc` first to ensure `PROGRESS/MEMORY/NEXT_STEP/.plan` are structurally valid.

### This Skill Must Produce
- A requirement snapshot that can be executed by `drive-pm-closed-loop` without additional interpretation.
- Suggested persistence path:
  - `.plan/{YYYYMMDD}_{feature}_requirement_v0.md`

### Required Handoff Fields
- `feature_name`
- `stage_name`
- `scope`
- `non_goals`
- `acceptance_criteria`
- `evidence_artifacts`
- `open_risks`
- `p0_next_candidate`

### Downstream Hand-off Rule
- After user confirms Requirement v0, hand off to `drive-pm-closed-loop` to freeze one minimum executable loop.
- Do not output roadmap expansion before `p0` blockers are answered.
