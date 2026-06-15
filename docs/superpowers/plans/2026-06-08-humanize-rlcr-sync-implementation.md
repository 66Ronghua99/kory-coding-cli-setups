---
doc_type: plan
status: in_progress
implements:
  - docs/superpowers/specs/2026-06-08-humanize-rlcr-sync-spec.md
verified_by:
  - bash tests/sync-agent-links/test-sync-agent-links.sh
  - ./sync-agent-links.sh --dry-run
  - command -v pwsh
supersedes: []
related:
  - docs/superpowers/plans/2026-06-08-sync-selected-superpowers-links-implementation.md
---

# Humanize RLCR Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make `sync-agent-links` install and update the Codex-side Humanize RLCR execution gate automatically while preserving Superpowers as the planning workflow.

**Architecture:** Reuse the existing sync script pattern for managed external checkouts. Add Humanize checkout variables and lifecycle functions, then call Humanize's installer instead of duplicating hook merge logic. Extend Bash tests with a fake Humanize remote and fake installer to prove the sync contract without touching the real user home.

**Tech Stack:** Bash, PowerShell, git, existing shell regression tests

---

**Allowed Write Scope:** `.gitignore`, `sync-agent-links.sh`, `sync-agent-links.ps1`, `tests/sync-agent-links/test-sync-agent-links.sh`, `docs/superpowers/specs/2026-06-08-humanize-rlcr-sync-spec.md`, `docs/superpowers/plans/2026-06-08-humanize-rlcr-sync-implementation.md`, `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`

**Verification Commands:** `bash tests/sync-agent-links/test-sync-agent-links.sh`, `./sync-agent-links.sh --dry-run`, `command -v pwsh`

**Evidence Location:** Inline command output in this session

**Rule:** Do not change the user's planning workflow. Humanize is installed only as a Codex RLCR execution gate.

---

## File Map

- Modify: `sync-agent-links.sh`
- Modify: `sync-agent-links.ps1`
- Modify: `tests/sync-agent-links/test-sync-agent-links.sh`
- Modify: `.gitignore`
- Create: `docs/superpowers/specs/2026-06-08-humanize-rlcr-sync-spec.md`
- Create: `docs/superpowers/plans/2026-06-08-humanize-rlcr-sync-implementation.md`
- Modify: `PROGRESS.md`
- Modify: `MEMORY.md`
- Modify: `NEXT_STEP.md`

## Tasks

### Task 1: Add Bash Regression Coverage

- [x] Extend `tests/sync-agent-links/test-sync-agent-links.sh` with fake Humanize remote helpers.
- [x] Add a test proving normal sync clones Humanize and invokes `scripts/install-skill.sh --target codex`.
- [x] Add a test proving reruns fast-forward the Humanize checkout and invoke the installer idempotently.
- [x] Add a test proving `HUMANIZE_SYNC=0` skips clone/install.
- [x] Add a test proving `--dry-run` can preview a missing Humanize checkout without requiring the installer file to already exist.
- [x] Add a static assertion that the generated `humanize/` checkout is ignored by git.
- [x] Run `TEST_FILTER=test_sync_installs_humanize_rlcr_for_codex bash tests/sync-agent-links/test-sync-agent-links.sh` and confirm the new test fails before implementation because the current script does not manage Humanize.

### Task 2: Implement Bash Humanize Sync

- [x] Add `HUMANIZE_DIR`, `HUMANIZE_REMOTE_URL`, `HUMANIZE_BRANCH`, and `HUMANIZE_SYNC` defaults to `sync-agent-links.sh`.
- [x] Add `ensure_humanize_repo` using the same clone, checkout, and fast-forward semantics as `ensure_superpowers_repo`.
- [x] Add `install_humanize_codex_rlcr` that runs `scripts/install-skill.sh --target codex` from the Humanize checkout.
- [x] Call the Humanize sync/install after Codex links are configured so Codex home paths exist.
- [x] Re-run Bash tests and confirm they pass.

### Task 3: Mirror PowerShell Behavior

- [x] Add matching Humanize variables to `sync-agent-links.ps1`.
- [x] Add `Ensure-HumanizeRepo` and `Install-HumanizeCodexRlcr` using the same explicit failure semantics.
- [x] Call the PowerShell Humanize sync/install at the same logical point as Bash.
- [x] Run `command -v pwsh`; unavailable locally, so PowerShell runtime verification is an explicit environment gap.

### Task 4: Sync Project Truth

- [x] Update `MEMORY.md` with the stable Humanize RLCR sync contract.
- [x] Update `PROGRESS.md` with the implementation and verification evidence.
- [x] Update `NEXT_STEP.md` to the only remaining executable pointer, or clear it if no follow-up remains.

## Completion Checklist

- [x] Spec requirements are covered
- [x] Bash verification was run fresh
- [x] PowerShell verification status is explicit
- [x] Repository state docs are updated
