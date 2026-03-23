---
doc_type: plan
status: implemented
implements:
  - docs/superpowers/specs/2026-03-23-cross-platform-sync-and-superpowers-bootstrap-design.md
verified_by: []
supersedes: []
related: []
---

# Cross-Platform Sync And Superpowers Bootstrap Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Spec Path:** `docs/superpowers/specs/2026-03-23-cross-platform-sync-and-superpowers-bootstrap-design.md`

**Goal:** Add first-class `superpowers` clone/update support to the sync flow and ship a Windows PowerShell sync script that mirrors the current Bash whole-directory sync behavior with hidden-directory targets.

**Architecture:** Keep the repository as the source of truth and preserve the existing whole-directory downstream `skills` mapping. The new behavior only adds `superpowers` lifecycle management: ensure the local `superpowers` checkout exists, optionally update it, and ensure `skills/superpowers` points at `superpowers/skills` before downstream sync runs. Bash and PowerShell keep native implementations and mostly share the same hidden-directory target mapping, with one intentional exception: Windows does not sync the Bash-only `statusline-command.sh`.

**Tech Stack:** Bash, PowerShell, git, filesystem symlinks, Windows junctions, lightweight shell-based regression tests

---

**Allowed Write Scope:** `sync-agent-links.sh`, `sync-agent-links.ps1`, `docs/project/README.md`, `docs/project/current-state.md`, `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, `docs/superpowers/specs/2026-03-23-cross-platform-sync-and-superpowers-bootstrap-design.md`, `docs/superpowers/plans/2026-03-23-cross-platform-sync-and-superpowers-bootstrap-implementation.md`, `tests/**`, `artifacts/sync-agent-links/**`

**Verification Commands:** `bash tests/sync-agent-links/test-sync-agent-links.sh`, `pwsh -NoProfile -File tests/sync-agent-links/test-sync-agent-links.ps1`

**Evidence Location:** `artifacts/sync-agent-links/`

**Rule:** Do not expand scope during implementation. New requests must be recorded through `CHANGE_REQUEST_TEMPLATE.md`.

---

## File Map

- Create: `sync-agent-links.ps1`
- Create: `tests/sync-agent-links/test-sync-agent-links.sh`
- Create: `tests/sync-agent-links/test-sync-agent-links.ps1`
- Modify: `sync-agent-links.sh`
- Modify: `docs/project/README.md`
- Modify: `docs/project/current-state.md`
- Modify: `PROGRESS.md`
- Modify: `MEMORY.md`
- Modify: `NEXT_STEP.md`

## Tasks

### Task 1: Lock The Desired Filesystem Contract With Tests

**Files:**
- Create: `tests/sync-agent-links/test-sync-agent-links.sh`
- Create: `tests/sync-agent-links/test-sync-agent-links.ps1`

- [x] Write the failing Bash regression test for:
  repository-local `skills/superpowers`, auto-clone on missing checkout, explicit update mode, downstream whole-directory `skills` sync, backup behavior, and idempotent reruns.
- [x] Run `bash tests/sync-agent-links/test-sync-agent-links.sh` and confirm it fails against the current Bash script for the expected missing-behavior reasons.
- [x] Write the failing PowerShell regression test for:
  hidden Windows-style target roots, repository-local `skills/superpowers` junction/link creation, whole-directory downstream `skills` sync, explicit update mode, and idempotent reruns.
- [ ] Run `pwsh -NoProfile -File tests/sync-agent-links/test-sync-agent-links.ps1` and confirm it fails because the PowerShell script does not exist yet.
- [x] Add red-state proof for required failure modes:
  missing `git`, existing non-git `superpowers` path, dirty checkout during update mode, and non-fast-forward update failure.

### Task 2: Refactor The Bash Sync Flow

**Files:**
- Modify: `sync-agent-links.sh`
- Test: `tests/sync-agent-links/test-sync-agent-links.sh`

- [x] Implement the smallest Bash changes that satisfy the new filesystem contract:
  `superpowers` is cloned when missing, `skills/superpowers` is repaired when needed, and explicit update mode uses fetch plus fast-forward-only update semantics while preserving the existing whole-directory downstream links.
- [x] Re-run `bash tests/sync-agent-links/test-sync-agent-links.sh` until it passes.
- [x] Keep clone/update failure behavior explicit for missing `git`, non-git checkout paths, dirty worktrees, and already-correct links.

### Task 3: Add The PowerShell Twin

**Files:**
- Create: `sync-agent-links.ps1`
- Test: `tests/sync-agent-links/test-sync-agent-links.ps1`

- [x] Implement the Windows sync script with the same target mapping semantics, using hidden directories under `$env:USERPROFILE`.
- [x] Use directory junctions for directory targets where that is the practical Windows equivalent, while keeping idempotent repeated runs.
- [ ] Re-run `pwsh -NoProfile -File tests/sync-agent-links/test-sync-agent-links.ps1` until it passes.

### Task 4: Document, Verify, And Sync Repository State

**Files:**
- Modify: `docs/project/README.md`
- Modify: `docs/project/current-state.md`
- Modify: `PROGRESS.md`
- Modify: `MEMORY.md`
- Modify: `NEXT_STEP.md`

- [x] Update repository docs so the one-command Bash and PowerShell sync entrypoints plus optional update mode are discoverable without reading script source.
- [ ] Run both verification commands fresh and store any needed notes under `artifacts/sync-agent-links/`.
- [x] Update repository state docs to record what changed, what was verified, and the next P0 pointer.

## Execution Truth

```yaml
schema: harness-execution-truth.v1
claims:
  - claim_id: plan.cross-platform-sync.superpowers-layout
    source_spec: docs/superpowers/specs/2026-03-23-cross-platform-sync-and-superpowers-bootstrap-design.md
    source_anchor: frozen_contracts
    source_hash: 1e37197dcc59fcd95a31b2c7859b3c5e18a93a55984c525dbdc56ab5b8b30350
```

## Completion Checklist

- [x] Spec requirements are covered
- [ ] Verification commands were run fresh
- [x] Evidence location is populated or explicitly noted
- [x] Repository state docs are updated
