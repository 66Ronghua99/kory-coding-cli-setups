---
name: superman
description: User-level macro workflow router for code engineering tasks in this environment. Use at the start of non-trivial coding work, large features, workflow changes, behavior changes, or ambiguous implementation requests to decide whether to take a lightweight path, run Superpowers brainstorming/writing-plans, or execute an approved plan through Humanize RLCR. Coordinates Superpowers as the design/planning source of truth and Humanize as the execution/review loop.
---

# Superman Development Flow

## Overview

Superman is the user-level routing layer for this development setup. It keeps the flow simple at the top: Superpowers owns discovery, design, and planning; Humanize owns implementation loops and external review; repository docs and fresh verification remain the handoff truth.

This skill is intentionally closer to `using-superpowers` than to a single feature checklist. Use it to choose the right route before doing work, then hand off to the narrower skills and tools that own each phase.

## Entry Protocol

1. Read `NEXT_STEP.md` and `MEMORY.md` before code work.
2. If status is unclear, also read `PROGRESS.md` and the active spec, plan, or checklist named by `NEXT_STEP.md`.
3. Invoke or follow `using-superpowers` when available so matching process skills still take precedence.
4. Classify the request into one route below.
5. Keep `NEXT_STEP.md` as a single pointer, and keep `PROGRESS.md` as a concise execution summary.

## Route Decision

### Lightweight Route

Use for small, well-bounded edits, local script work, doc cleanup, or low-risk fixes where the target behavior is already clear.

- Read only the local context needed to make the change safely.
- Use the matching domain skill if one exists.
- Implement directly, verify with the strongest relevant command, and update docs only when the change affects the repository truth.
- Do not create a full spec or plan just to satisfy process.

### Design And Plan Route

Use for large features, behavior changes, workflow changes, significant refactors, cross-module changes, or requests with meaningful ambiguity.

1. Use `superpowers:brainstorming` to explore intent and freeze the design.
2. Store the approved spec locally under the repository's declared spec path, normally `docs/superpowers/specs/`; do not stage, commit, or push it.
3. Use `superpowers:writing-plans` to produce the local implementation plan and checklist, normally under `docs/superpowers/plans/`; do not stage, commit, or push it.
4. Keep only one main loop active in `NEXT_STEP.md`.

`PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, `docs/superpowers/`, and `artifacts/` are local-only collaboration state. This policy overrides upstream Superpowers wording that asks for spec or plan commits.

### Humanize Execution Route

Use when there is an approved plan or a clearly frozen implementation checklist for a substantial feature.

1. Start `humanize-rlcr` with the active plan file.
2. Treat Humanize's generated round prompts, summaries, review results, and goal tracker as the execution loop truth.
3. Let the Humanize Stop hook enforce review and continuation. Do not manually edit Humanize state files or bypass blocked hook feedback.
4. For parallel work, prefer Humanize agent teams or the current platform's subagent/worktree support when available; keep the main session as coordinator.

### Repository Governance Route

Use `harness:init` only for missing collaboration skeletons. Use `harness:doc-health` only when repository pointers, docs, specs, plans, or evidence have drifted.

`harness:lint-test-design` and `harness:refactor` are not part of this user-level workflow. Prefer normal tests, code review, and concrete follow-up tasks instead of routing to those skills.

## Review And Verification

- Before claiming completion, run the repository's declared quality gate.
- If no gate is declared, run the strongest relevant `test`, `typecheck`, `build`, or smoke command available.
- Use `verification-before-completion` when available before any final success claim.
- Use Humanize's review phase for substantial implementation work.
- Optional one-shot Codex consultation through Humanize's `ask-codex.sh` may be used only when it is installed and useful; it is not a hard dependency.

## Handoff

Every delivery should state:

- which loop closed
- where the fresh evidence lives
- what remains incomplete, if anything
- the next `P0` action, or that `NEXT_STEP.md` is clear
