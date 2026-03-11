# MEMORY

## Reusable Lessons

### PM Boundary
- Symptom: requirement discussion and execution planning collapse into one step.
- Root Cause: `pm-progress` and `drive-pm-closed-loop` both tried to clarify scope and define next actions.
- Fix: keep `pm-progress` focused on requirement freeze only, and let `drive-pm-closed-loop` start only after scope and acceptance criteria are explicit.
- Prevention: require a requirement snapshot before closed-loop planning.

### Agent Routing
- Symptom: the main agent absorbs exploration, architecture, and review work, so task boundaries blur.
- Root Cause: there was no project-local role map or Codex role config.
- Fix: add dedicated `explorer`, `architect`, and `reviewer` agent roles plus a root routing index.
- Prevention: when adding a new workflow, define whether it belongs to an agent, a skill, or the root instructions.

### Indexing
- Symptom: supporting docs inside `docs/` are easy to miss.
- Root Cause: AGENTS entrypoints did not explicitly link a routing index.
- Fix: keep the routing map at repository root as `AGENT_INDEX.md` and reference it directly from `AGENTS.md`.
- Prevention: any operational index must be linked from the root instruction file.
