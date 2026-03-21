---
name: harness:doc-health
description: Use when repository docs may be stale, top-level pointers disagree, an active spec-plan-evidence chain may have drifted, or a recurring doc-gardening pass is needed.
---

# harness:doc-health

`harness:doc-health` keeps repository knowledge usable by agents.

OpenAI's Harness pattern is to keep `AGENTS.md` short, treat repo-local docs as the system of record, and continuously remove drift. This skill is for that audit. It is not a checker, lint pack, or architecture review.

## When To Use

Use this skill when:

- `PROGRESS.md`, `NEXT_STEP.md`, `MEMORY.md`, `AGENT_INDEX.md`, or `.harness/bootstrap.toml` might disagree
- an active spec, plan, or evidence artifact may no longer match current repository truth
- a repo needs recurring doc-gardening instead of ad hoc cleanup
- one specific spec or plan needs a bounded coherence review before work continues

Do not use this skill for lint/test invariant design or code-architecture drift review.

## Core Questions

- Is the repository knowledge base still the system of record?
- Is `AGENTS.md` acting like a map instead of a long manual?
- Is there one clear active spec, one matching plan, and current evidence?
- Are status markers, next actions, and ownership boundaries still unambiguous?
- Should any recurring document issue become a mechanical check instead of more prose?

## Working Shape

1. Read the top-level pointers first.
2. Find the active spec, active plan, and freshest evidence.
3. Check pointer consistency, status lifecycle, and spec-plan-evidence continuity.
4. Return the minimal fixes needed to restore truth.
5. If the same drift keeps recurring, recommend a repo-local check or recurring cleanup pass.

This often runs as a background doc-gardening task, but the value is the audit model, not the dispatch pattern.

## Expected Output

- concise findings with severity, file paths, and line references when available
- corrected pointer or status updates
- refreshed truth blocks or evidence links
- for a single oversized spec/plan: keep, split, or blocking-inconsistency
- note on which issue should stay editorial vs become mechanical

## Guardrails

- Prefer progressive disclosure over bigger instruction blobs.
- Fix source-of-truth drift before adding more process.
- Keep focused reviews bounded to the target doc plus required upstream or downstream references.
- Do not treat stale code architecture as doc-health; route that through `harness:refactor`.
- Do not treat enforceable structure or behavior policy as doc-health; route that through `harness:lint-test-design`.

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
