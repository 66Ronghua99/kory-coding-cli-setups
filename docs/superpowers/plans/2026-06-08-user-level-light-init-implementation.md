---
doc_type: plan
status: implemented
implements:
  - docs/superpowers/specs/2026-06-08-user-level-light-init-spec.md
verified_by:
  - rg -n "\\.harness|AGENT_INDEX\\.md|PROJECT_LOGS\\.md|bootstrap manifest|bootstrap.toml" AGENTS.md MEMORY.md skills/harness-init skills/harness-doc-health harness-bootstrap
  - bash harness-bootstrap/scripts/validate_bootstrap.sh /Users/cory/.coding-cli
supersedes: []
related: []
---

# User-Level Light Init Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Spec Path:** `docs/superpowers/specs/2026-06-08-user-level-light-init-spec.md`

**Goal:** Shrink the user-level Harness bootstrap to a minimal collaboration baseline with no `.harness`, `AGENT_INDEX.md`, `PROJECT_LOGS.md`, or `PROCESS.md` dependency.

**Architecture:** Rewrite the user-level policy and Harness init skill so they point at a lighter collaboration model, then make the bootstrap pack generate and validate only that minimal file set. Finish by syncing this repository's own state docs to the new contract.

**Tech Stack:** Markdown docs, shell bootstrap scripts, ripgrep-based verification

---

**Allowed Write Scope:** `AGENTS.md`, `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, `docs/superpowers/specs/2026-06-08-user-level-light-init-spec.md`, `docs/superpowers/plans/2026-06-08-user-level-light-init-implementation.md`, `skills/harness-init/**`, `skills/harness-doc-health/**`, `harness-bootstrap/**`, `docs/superpowers/templates/README.md`

**Verification Commands:** `rg -n "\\.harness|AGENT_INDEX\\.md|PROJECT_LOGS\\.md|bootstrap manifest|bootstrap.toml" AGENTS.md MEMORY.md skills/harness-init skills/harness-doc-health harness-bootstrap`, `bash harness-bootstrap/scripts/validate_bootstrap.sh /Users/cory/.coding-cli`

**Evidence Location:** Inline command output in this session

**Rule:** Do not expand scope during implementation. New requests must be recorded through `CHANGE_REQUEST_TEMPLATE.md`.

---

## File Map

- Create: `docs/superpowers/specs/2026-06-08-user-level-light-init-spec.md`
- Create: `docs/superpowers/plans/2026-06-08-user-level-light-init-implementation.md`
- Modify: `AGENTS.md`
- Modify: `PROGRESS.md`
- Modify: `MEMORY.md`
- Modify: `NEXT_STEP.md`
- Modify: `skills/harness-init/**`
- Modify: `skills/harness-doc-health/**`
- Modify: `harness-bootstrap/**`
- Delete: `AGENT_INDEX.md`
- Delete: `harness-bootstrap/skeleton/AGENT_INDEX.md`
- Delete: `harness-bootstrap/skeleton/.harness/bootstrap.toml.example`

## Tasks

### Task 1: Prove The Old Bootstrap Contract Exists

- [x] Run a focused `rg` search for `.harness`, `AGENT_INDEX.md`, `PROJECT_LOGS.md`, and bootstrap-manifest wording in the user-level bootstrap surfaces.
- [x] Confirm the current repository still depends on the retired contract and therefore needs the planned rewrite.

### Task 2: Rewrite Policy And Skill Truth

- [x] Update `AGENTS.md`, `skills/harness-init/**`, and `skills/harness-doc-health/**` to describe the minimal file set, pointer-based recovery flow, and goal-end file-state review expectation.
- [x] Remove retired references to `.harness`, `AGENT_INDEX.md`, `PROJECT_LOGS.md`, and manifest-based truth from those surfaces.

### Task 3: Rewrite Bootstrap Skeleton And Validation

- [x] Remove retired skeleton assets and update bootstrap scripts so they only copy and validate the new minimal file set plus templates.
- [x] Keep migration bootstrap additive and preserve the existing project-state docs/templates that are still part of the lightweight baseline.

### Task 4: Sync Repository State And Verify

- [x] Update this repository's `PROGRESS.md`, `MEMORY.md`, and `NEXT_STEP.md` so they match the new model.
- [x] Re-run the focused `rg` search and `bash harness-bootstrap/scripts/validate_bootstrap.sh /Users/cory/.coding-cli` to confirm the green state.

## Execution Truth

```yaml
schema: harness-execution-truth.v1
claims:
  - claim_id: plan.user-level-light-init.minimal-baseline
    source_spec: docs/superpowers/specs/2026-06-08-user-level-light-init-spec.md
    source_anchor: frozen_contracts
    source_hash: ec133b480932ac85eb646b4a4da8cbc327f68de2f59925fc5d5a2ae4f6b1ddf2
```

## Completion Checklist

- [x] Spec requirements are covered
- [x] Verification commands were run fresh
- [x] Evidence location is populated or explicitly noted
- [x] Repository state docs are updated
