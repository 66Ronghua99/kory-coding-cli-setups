# Agent Harness Restructure

## Problem
- The current harness relies heavily on one large instruction surface.
- PM requirement discovery is frequently skipped because its role overlaps with closed-loop planning.
- There is no project-local Codex agent layer for exploration, architecture, and review.

## Boundary
- In scope:
  - Add project-local Codex multi-agent role configuration.
  - Add a root routing index for agent and skill selection.
  - Clarify PM workflow separation.
  - Add missing architecture and verification workflow skills.
- Out of scope:
  - Hook systems copied from Claude/Cursor ecosystems.
  - Automated validators or CI for the harness.
  - Large-scale skill imports from ECC.

## Options
- Option A: keep everything in `AGENTS.md`.
  - Rejected because responsibility boundaries stay implicit.
- Option B: add role files plus routing docs and tighten skill boundaries.
  - Chosen because it improves maintainability with minimal moving parts.

## Migration
- Add `.codex/config.toml` with `multi_agent = true`.
- Add `.codex/agents/` role files for `explorer`, `architect`, `reviewer`.
- Add `AGENT_INDEX.md` as the routing map referenced by `AGENTS.md`.
- Rewrite PM skills to separate requirement freeze from execution planning.
- Add `architecture-review` and `verification-loop` skills.

## Test Strategy
- Structural verification:
  - Confirm all new files exist and are referenced by `AGENTS.md` and `PROGRESS.md`.
- Workflow verification:
  - On the next real task, check whether routing is unambiguous for exploration, architecture, review, and verification.
- Regression guard:
  - Ensure `NEXT_STEP.md` matches `PROGRESS.md` `P0-NEXT`.
