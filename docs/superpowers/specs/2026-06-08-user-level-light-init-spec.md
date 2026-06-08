---
doc_type: spec
status: approved
supersedes: []
related: []
---

# User-Level Light Init Spec

## Problem

The current user-level Harness bootstrap is heavier than desired. It still treats `.harness/bootstrap.toml`, `AGENT_INDEX.md`, and `PROJECT_LOGS.md` as required governance surfaces, which conflicts with the new goal of a smaller repository baseline driven by only a few durable collaboration files plus Superpowers templates.

## Success

- `harness:init` only creates the minimal user-level collaboration files plus `docs/superpowers/templates/`.
- The user-level policy no longer depends on `.harness/`, `AGENT_INDEX.md`, `PROJECT_LOGS.md`, or `PROCESS.md`.
- Context recovery guidance favors `NEXT_STEP.md`, current spec/plan/checklist state, and targeted code review over log-style replay.

## Out Of Scope

- Replacing the existing Superpowers spec/plan template system.
- Adding a runtime automation layer that hooks directly into goal lifecycle events.

## Critical Paths

1. Rewrite the user-level policy and bootstrap skill so they describe the new minimal file set and recovery workflow.
2. Update the bootstrap skeleton and scripts so generated repositories match the new contract.
3. Refresh repository state docs so this repository itself reflects the lighter model.

## Frozen Contracts
<!-- drift_anchor: frozen_contracts -->

- `harness:init` creates only `AGENTS.md`, `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, and `docs/superpowers/templates/` as the required collaboration baseline.
- `NEXT_STEP.md` is a pointer-only file; it references the active spec, plan, or checklist, and it is cleared when no next task exists.
- `PROGRESS.md` is an accumulating execution summary for agents and is not mandatory reading on every turn.
- When current state is unclear, agents recover truth from `NEXT_STEP.md`, spec/plan chronology, checklist completion, and bounded code review.
- Goal completion should trigger a default file-state review as a workflow expectation, even if no runtime hook exists yet.

## Architecture Invariants

- User-level bootstrap must stay human-readable and avoid hidden manifest-based truth sources.
- Stable guidance belongs in `AGENTS.md` and `MEMORY.md`; process flow state belongs in spec/plan/checklist plus `NEXT_STEP.md`.
- Bootstrap validation must check the minimal required file set and template presence, not retired governance metadata.

## Failure Policy

- If required baseline files are missing after bootstrap, validation should fail explicitly and name each missing path.
- If task state is ambiguous, agents should resolve it by checking current spec/plan/checklist truth rather than inventing progress from memory.

## Acceptance
<!-- drift_anchor: acceptance -->

- Search-based verification shows the old `.harness`, `AGENT_INDEX.md`, and `PROJECT_LOGS.md` requirements are removed from the updated user-level bootstrap surfaces.
- The bootstrap validation script passes against the updated repository layout.

## Deferred Decisions

- Whether the goal-completion file-state review should later become a real runtime hook instead of a documented workflow rule.
