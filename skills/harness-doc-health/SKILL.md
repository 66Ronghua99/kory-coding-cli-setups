---
name: harness:doc-health
description: Use when a repository needs its source-of-truth documents checked for pointer drift, spec-plan-evidence drift, stale status, mismatch between current progress and recorded next actions, or focused quality review of a single spec/plan.
---

# harness:doc-health

`harness:doc-health` is the golden standard for repository truth.

It does not ship a checker. It tells coding agents how to inspect whether the repository's governance docs, active specs, active plans, and recorded evidence still agree with each other.

## Default Execution Mode

Run `harness:doc-health` in a background subagent by default.

The main session should dispatch the audit, keep working on non-overlapping critical-path tasks, and only integrate the findings when they are needed. Do not run the full doc-health audit inline in the main session unless the user explicitly forbids subagents or the environment cannot run them.

## Focused Single-Document Review Mode

When the user asks to review **one specific spec or plan**, dispatch a **single focused subagent** for that file instead of a full repository audit.

### Input Contract For Focused Review

Pass all of the following in the subagent task:

- absolute file path
- declared doc type (`spec` or `plan`)
- review intent (`granularity`, `consistency`, `drift risk`, or `all`)
- whether hard blocking findings are expected (`yes` or `no`)

### Focused Review Checks

For a `spec`, the subagent should check:

- scope granularity: whether the document carries more than one independent capability loop
- contract coherence: contradictory enums, status semantics, or ownership boundaries
- content boundary: implementation/runbook material mixed into behavior contract sections
- acceptance traceability: each acceptance statement can map to concrete evidence

For a `plan`, the subagent should check:

- scope containment: each task still maps to the approved spec scope
- execution granularity: tasks are bite-sized and independently reviewable
- truth continuity: execution truth claims point to current spec anchors
- verification continuity: plan outcomes can be proven by evidence artifacts

### Recommended Split Signals (Soft Guidance)

For spec granularity, propose split when one or more of these appears:

- `Critical Paths` exceed 2
- `Frozen Contracts` exceed ~12 items
- `Acceptance` exceeds ~3 items
- multiple independent runtime boundaries are changed in one doc
- reviewers cannot explain the end-to-end loop in one pass

### Required Focused Output

The subagent output must include:

1. verdict: `keep-single-doc` | `split-recommended` | `blocking-inconsistency`
2. findings list with severity, file path, and line references
3. if split is recommended: a concrete split map (`umbrella` + capability docs)
4. minimal rewrite guidance that the main session can apply immediately

## When To Use

Use this skill when:

- starting complex work and the current repository state might be stale
- `PROGRESS.md`, `NEXT_STEP.md`, `MEMORY.md`, or `AGENT_INDEX.md` may be out of sync
- an active spec, plan, or evidence file might no longer reflect the current implementation truth
- a completion claim needs document evidence, not just command output
- recurring document audits are needed to prevent drift
- a single spec/plan needs focused granularity and coherence review before execution

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

1. Dispatch a background subagent to run the doc-health audit.
2. In the subagent, read `PROGRESS.md`, `NEXT_STEP.md`, `MEMORY.md`, and `AGENT_INDEX.md` first.
3. Identify the active spec, active plan, and freshest evidence for the current loop.
4. Compare pointers, statuses, and truth blocks using the references and templates in this skill.
5. Return concise findings and proposed doc fixes to the main session.
6. Update the source-of-truth documents before continuing implementation.
7. Record the audit result in repository evidence when the drift check matters to delivery.

For focused single-document review, skip unrelated repository-wide checks and keep the audit bounded to the target doc plus minimally required upstream/downstream references.

## Expected Outputs

A good `harness:doc-health` run by a subagent should produce some combination of:

- corrected pointer docs
- corrected metadata or status transitions
- refreshed `Execution Truth` or `Verified Claims` blocks
- a short audit note or evidence file showing what drift was found and resolved
- a concise findings summary that the main session can integrate without re-running the audit inline

In focused mode, output should remain single-file-centric and avoid broad repo cleanup suggestions unless they directly block the target document.

## Guardrails

- Do not run the full doc-health audit in the main session when a background subagent can do it.
- Do not treat focused single-document review as free-form prose feedback; return structured findings and a clear verdict.
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
