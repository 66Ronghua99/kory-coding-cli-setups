---
name: grill-with-docs
description: Stress-test and harden Superpowers specs before planning or execution. Use when the user asks for grill-me-doc, grill-with-docs, spec grilling, spec review, or wants to pressure-test a draft/active spec against repository docs, code reality, failure policy, frozen contracts, acceptance criteria, and the user's NEXT_STEP/MEMORY workflow.
---

# Grill Specs With Docs

Use this skill to turn a fuzzy or under-specified design into an execution-ready Superpowers spec. The default output is an improved spec, not a standalone glossary.

## Operating Rule

Interview the user relentlessly but efficiently. Ask one question at a time, provide your recommended answer, and wait for feedback before moving to the next question.

If a question can be answered by reading the repository, read the repository instead of asking.

## Project Truth Model

Prefer the user's lightweight collaboration spine:

1. `NEXT_STEP.md` - current active pointer
2. `MEMORY.md` - stable project lessons and constraints
3. active `docs/superpowers/specs/*.md`
4. active `docs/superpowers/plans/*.md` or checklist, only when it already exists
5. `PROGRESS.md`, only when state or task boundary is unclear
6. code and tests needed to verify claims in the spec

Do not create `CONTEXT.md`, `CONTEXT-MAP.md`, or `docs/adr/` by default. Those files are optional compatibility surfaces for projects that already use them or for users who explicitly ask for domain glossary/ADR capture.

## When To Use

Use for:

- a draft spec that needs stronger coverage before approval
- an approved spec that feels too loose before planning
- an implementation plan that may be drifting because the spec is underspecified
- user requests such as "grill this spec", "help me improve spec quality", "find missing spec details", or "avoid execution ambiguity"

Do not use as a replacement for `brainstorming` when there is no written spec or stable requirement artifact yet. In that case, route to `brainstorming` first.

## Default Flow

### 1. Orient

- Read `NEXT_STEP.md` and `MEMORY.md`.
- Locate the active spec from `NEXT_STEP.md`, user input, or the latest relevant file under `docs/superpowers/specs/`.
- Read the active plan/checklist only if `NEXT_STEP.md` points to one or if the user is grilling plan/spec alignment.
- Read `PROGRESS.md` only when status is unclear.
- Skim the smallest relevant code/test surface when the spec makes claims about existing behavior.

State the active spec path and the grill target before starting questions.

### 2. Build The Grill Map

Extract unresolved or weak spots from the spec using these lenses:

- **Problem:** Is the real pain explicit, current, and narrow enough?
- **Success:** Are success signals observable rather than vibes?
- **Out Of Scope:** Are tempting adjacent requests excluded?
- **Critical Paths:** Are the user/system workflows concrete enough to implement?
- **Frozen Contracts:** Are public interfaces, file paths, flags, schemas, hooks, and compatibility promises named?
- **Architecture Invariants:** Are boundaries and ownership rules stated so implementation cannot drift?
- **Failure Policy:** Are invalid states, missing dependencies, and allowed fallbacks explicit?
- **Acceptance:** Can verification commands or evidence prove the spec is satisfied?
- **Deferred Decisions:** Are true deferrals isolated from execution blockers?
- **Plan Readiness:** Could another agent write a checklist from this spec without guessing?

Prioritize questions that prevent implementation ambiguity. Do not exhaustively ask about low-impact details.

### 3. Question Discipline

For each question:

1. Name the affected spec section.
2. Explain the ambiguity or risk in one or two sentences.
3. Give a recommended answer.
4. Ask for confirmation or correction.

Example:

> **Frozen Contracts:** The spec says the sync flow "installs a runtime hook", but does not name whether the repository or the upstream installer owns hook configuration changes. My recommendation: freeze one owner and require that path to preserve unrelated hooks. Is that right?

### 4. Patch As Decisions Crystallize

When the user resolves a point, update the spec immediately:

- Preserve frontmatter, headings, and drift anchors.
- Keep `status: draft` unless the user explicitly approves the spec.
- Add concrete bullets to the relevant section instead of appending chat notes.
- Move execution-blocking unknowns out of `Deferred Decisions`; either resolve them or mark the spec not ready for planning.
- If an active plan already exists and the spec change invalidates it, update the plan/checklist or mark the required follow-up in `NEXT_STEP.md`.

Only update `MEMORY.md` for stable, reusable lessons. Only update `PROGRESS.md` for execution summaries, not interview transcript. Keep `NEXT_STEP.md` as a single direct pointer.

### 5. Optional Domain Docs

Use `CONTEXT.md` only when all are true:

- the repository already uses `CONTEXT.md`/`CONTEXT-MAP.md`, or the user explicitly asks to maintain a glossary
- the decision is about domain language, not implementation behavior
- the term is stable enough to help future agents

When needed, follow [CONTEXT-FORMAT.md](./CONTEXT-FORMAT.md).

Offer an ADR only when all are true:

- hard to reverse
- surprising without context
- the result of a real trade-off

When needed, follow [ADR-FORMAT.md](./ADR-FORMAT.md).

### 6. Stop Conditions

Stop grilling when either:

- every high-impact ambiguity has been resolved or explicitly deferred without blocking planning, or
- the user pauses the session.

At the end, report:

- spec path changed
- major decisions captured
- unresolved blockers, if any
- next `P0` action for `NEXT_STEP.md`
- verification or review evidence used

## Anti-Patterns

- Creating `CONTEXT.md` just because the original skill mentioned it.
- Treating `CONTEXT.md` as a spec, scratchpad, or implementation checklist.
- Asking the user questions that the codebase can answer.
- Letting `Deferred Decisions` hide details required for execution.
- Updating `PROGRESS.md` with a transcript of the grilling session.
- Marking a spec approved without explicit user approval.
