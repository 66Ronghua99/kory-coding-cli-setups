---
doc_type: plan
status: in_progress
implements:
  - docs/superpowers/specs/2026-06-08-sync-selected-superpowers-links-spec.md
verified_by:
  - bash tests/sync-agent-links/test-sync-agent-links.sh
  - command -v pwsh
supersedes: []
related:
  - docs/superpowers/plans/2026-03-23-cross-platform-sync-and-superpowers-bootstrap-implementation.md
---

# Sync Selected Superpowers Links Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Spec Path:** `docs/superpowers/specs/2026-06-08-sync-selected-superpowers-links-spec.md`

**Goal:** Make sync-agent-links auto-manage the `superpowers` checkout and expose only a curated top-level set of `superpowers` skills.

**Architecture:** Teach Bash and PowerShell sync scripts to clone or fast-forward `superpowers`, generate selected top-level links under `skills/`, remove the old nested `skills/superpowers` exposure, and sync Codex directly to `.codex/skills`. Lock the contract with regression tests and ignore generated curated links in git.

**Tech Stack:** Bash, PowerShell, git, symlinks/junctions, shell regression tests

---

**Allowed Write Scope:** `sync-agent-links.sh`, `sync-agent-links.ps1`, `tests/sync-agent-links/**`, `.gitignore`, `MEMORY.md`, `PROGRESS.md`, `NEXT_STEP.md`, `docs/superpowers/specs/2026-06-08-sync-selected-superpowers-links-spec.md`, `docs/superpowers/plans/2026-06-08-sync-selected-superpowers-links-implementation.md`

**Verification Commands:** `bash tests/sync-agent-links/test-sync-agent-links.sh`, `pwsh -NoProfile -File tests/sync-agent-links/test-sync-agent-links.ps1`

**Evidence Location:** Inline command output in this session

**Rule:** Do not expand scope during implementation. New requests must be recorded through `CHANGE_REQUEST_TEMPLATE.md`.

---

## File Map

- Create: `docs/superpowers/specs/2026-06-08-sync-selected-superpowers-links-spec.md`
- Create: `docs/superpowers/plans/2026-06-08-sync-selected-superpowers-links-implementation.md`
- Modify: `sync-agent-links.sh`
- Modify: `sync-agent-links.ps1`
- Modify: `tests/sync-agent-links/test-sync-agent-links.sh`
- Modify: `tests/sync-agent-links/test-sync-agent-links.ps1`
- Modify: `.gitignore`
- Modify: `MEMORY.md`
- Modify: `PROGRESS.md`
- Modify: `NEXT_STEP.md`

## Tasks

### Task 1: Rewrite Regression Truth

- [x] Update Bash and PowerShell sync regression tests to assert:
  curated top-level `skills/<name>` links, no `skills/superpowers`, auto clone/pull behavior, and Codex `.codex/skills` direct mapping.
- [x] Run the Bash test to confirm the current implementation fails under the new contract.

### Task 2: Implement Curated Sync Behavior

- [x] Update Bash and PowerShell sync scripts to clone or fast-forward `superpowers`, generate only the curated top-level links, and clean up the old nested model.
- [x] Preserve explicit failure semantics and idempotent reruns.

### Task 3: Guard Git State And Sync Docs

- [x] Ignore generated curated skill links in git.
- [x] Update repository state docs so the new curated export model and empty-next-step rule remain accurate.

### Task 4: Verify And Close The Loop

- [ ] Re-run Bash and PowerShell verification commands successfully.
- [x] Mark the plan state and repository docs with the current Bash-pass / PowerShell-gap status.

## Execution Truth

```yaml
schema: harness-execution-truth.v1
claims:
  - claim_id: plan.sync-selected-superpowers-links.curated-export
    source_spec: docs/superpowers/specs/2026-06-08-sync-selected-superpowers-links-spec.md
    source_anchor: frozen_contracts
    source_hash: fcde062706aec4a9e4b2e3145911dc4dd41651614ef72c262dab67b3df2192c9
```

## Completion Checklist

- [x] Spec requirements are covered
- [ ] Verification commands were run fresh
- [x] Evidence location is populated or explicitly noted
- [x] Repository state docs are updated
