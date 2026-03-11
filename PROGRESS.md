# PROGRESS

## Current Milestone
- Build a role-based Codex harness with explicit routing for exploration, architecture, PM freeze, closed-loop execution, review, and verification.

## TODO
- P0-NEXT: Exercise the new `explorer -> architect -> reviewer -> verification-loop` path on the next real repository task and adjust routing gaps based on evidence.

## DONE
- Initialized core project control docs: `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, and `.plan/` skeleton.
- Added project-local Codex multi-agent config and role files for `explorer`, `architect`, and `reviewer`.
- Clarified PM skill boundaries so requirement freeze and closed-loop planning are separate stages.
- Added `verification-loop` and `architecture-review` skills plus a root `AGENT_INDEX.md` routing map.

## Reference List
- `AGENTS.md`
- `AGENT_INDEX.md`
- `.codex/config.toml`
- `.codex/agents/explorer.toml`
- `.codex/agents/architect.toml`
- `.codex/agents/reviewer.toml`
- `.plan/20260311_agent_harness_restructure.md`
- `.plan/checklist_agent_harness_restructure.md`
