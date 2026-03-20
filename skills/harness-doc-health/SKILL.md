---
name: harness:doc-health
description: Use when a repository needs its source-of-truth documents checked for pointer drift, spec-plan-evidence drift, stale status, or mismatch between current progress and recorded next actions.
---

# harness:doc-health

`harness:doc-health` is the golden standard for repository truth.

It does not ship a checker. It tells coding agents how to inspect whether the repository's governance docs, active specs, active plans, and recorded evidence still agree with each other.

## When To Use

Use this skill when:

- starting complex work and the current repository state might be stale
- `PROGRESS.md`, `NEXT_STEP.md`, `MEMORY.md`, or `AGENT_INDEX.md` may be out of sync
- an active spec, plan, or evidence file might no longer reflect the current implementation truth
- a completion claim needs document evidence, not just command output
- recurring document audits are needed to prevent drift

Do not use this skill to define lint rules, test strategy, or runtime automation.

## Health Domains

### 1. Bootstrap Integrity

Confirm the repository has the minimum governance surface:

- root docs exist and have distinct roles
- `.harness/bootstrap.toml` matches the active Harness model
- document templates exist where the repo says they exist

### 2. Pointer Consistency

Confirm the top-level pointers agree:

- `PROGRESS.md` active milestone matches the live loop
- `NEXT_STEP.md` names one direct next action only
- `MEMORY.md` stores durable lessons, not transient task lists
- `AGENT_INDEX.md` routes to the active skill taxonomy

### 3. Spec -> Plan -> Evidence Integrity

Confirm the execution chain is explicit:

- active specs expose stable contracts and acceptance criteria
- active plans implement an active spec and record execution truth
- evidence files point back to the plan they verify
- statuses (`draft`, `active`, `superseded`, `archived`) do not contradict each other

### 4. Drift And Freshness

Confirm the recorded truth is still current:

- changes in frozen contracts are reflected in plan execution truth
- changes in plan claims are reflected in verification evidence
- completion claims have fresh, reviewable proof

## Operating Model

1. Read `PROGRESS.md`, `NEXT_STEP.md`, `MEMORY.md`, and `AGENT_INDEX.md` first.
2. Identify the active spec, active plan, and freshest evidence for the current loop.
3. Compare pointers, statuses, and truth blocks using the references and templates in this skill.
4. Fix the source-of-truth documents before continuing implementation.
5. Record the audit result in repository evidence when the drift check matters to delivery.

## Expected Outputs

A good `harness:doc-health` run by an agent should produce some combination of:

- corrected pointer docs
- corrected metadata or status transitions
- refreshed `Execution Truth` or `Verified Claims` blocks
- a short audit note or evidence file showing what drift was found and resolved

## Guardrails

- Do not pretend a prose-only judgment is machine-checkable.
- Do not hide document policy inside helper scripts.
- Do not mark work complete when evidence or pointer docs are stale.
- Do not let archived or superseded docs continue acting as active truth.
- Do not treat lint/test failures as doc-health findings; route those through `harness:lint-test-design` and the normal coding workflow.

## Reference Pack

- `references/health-model.md`
- `references/pointer-consistency.md`
- `references/spec-plan-evidence-drift.md`
- `references/status-lifecycle.md`
- `templates/spec-and-plan-truth.template.md`
- `templates/evidence-verified-claims.template.md`
- `checklists/pre-implementation-doc-audit.md`
- `checklists/pre-delivery-doc-audit.md`
- `examples/healthy-doc-chain.md`
- `examples/pointer-drift.md`
