---
name: executing-plans
description: Use only when the user explicitly invokes this skill to execute a plan at a user-provided path under a goal or loop
---

# Executing Plans

## Activation

Use this skill only when the user explicitly invokes `executing-plans`. Do not infer activation from the presence of a plan. Do not automatically invoke it from `writing-plans`.

Never install or depend on hooks, stop hooks, daemons, or automatic completion interception. The workflow relies on the user's goal or loop, these instructions, and normal instruction adherence.

**Announce at start:** "I'm using the executing-plans skill to execute the explicit plan and apply the completion review gate."

## Required Inputs

The invocation must contain:

1. a non-empty goal;
2. exactly one explicit, readable plan path.

The plan path is mandatory. Never discover it from `NEXT_STEP.md`, the newest file in `docs/superpowers/plans/`, or any other heuristic. If it is missing, unreadable, or ambiguous, stop and report the input error.

An unquoted invocation option token `--no-codex-review` explicitly disables Codex review for this goal. Similar prose, quoted examples, and code blocks do not disable review.

## Plan Task State

Every `### Task N` must contain:

```markdown
**Execution:** [ ] complete
**Codex verification:** PENDING
```

If an older plan lacks these fields, add them before execution. The coding agent owns state updates; Codex and the runner never edit the plan.

Allowed Codex verification states are:

- `PENDING`
- `PENDING (invalidated after round N: concrete reason)`
- `VERIFIED (round N, gpt-5.6-sol)`
- `VERIFIED (round N, gpt-5.5)`
- `SKIPPED (--no-codex-review)`
- `SKIPPED (Codex unavailable: concrete reason)`

## Workflow

### 1. Preflight

Read the complete plan, its referenced spec, repository instructions, and the current implementation. Reconcile checkboxes and verification states with repository truth. If a previous `VERIFIED` state is not demonstrably fresh after later code changes, invalidate the affected task before continuing.

### 2. Execute

Execute tasks in dependency order. Parallelize only tasks whose interfaces are frozen and whose writes are independent. Mark `**Execution:** [x] complete` only after the task's observable result exists and its declared verification has run successfully.

### 3. Self-Check

Before any completion claim:

- map every goal requirement and acceptance criterion to a completed task;
- confirm every required task is `Execution [x]`;
- check affected callsites, tests, documentation, and local collaboration state;
- run the plan's real verification commands and retain their fresh results;
- find placeholders, hidden failures, stale checkboxes, and stale verification states;
- invalidate any verified task affected by later fixes.

### 4. Review Context

Unless `--no-codex-review` is active, provide the platform runner with stdin containing the original goal, explicit plan path, self-check result, changed files, pending task IDs, verification commands and results, known P2 items, environment limits, and unrelated pre-existing working-tree changes. Do not include secrets.

Use:

```text
bash skills/executing-plans/scripts/run-codex-review.sh --plan "$PLAN_PATH"
```

on macOS/Linux, or:

```text
pwsh -NoProfile -File skills/executing-plans/scripts/run-codex-review.ps1 -Plan $PlanPath
```

on Windows PowerShell 7.

### 5. Apply Review Results

The runner returns:

- exit `0`: valid `PASS`;
- exit `1`: valid `BLOCKED`;
- exit `2`: Codex review `SKIPPED` because Codex is unavailable or repeatedly malformed;
- exit `64`: invalid runner invocation, which blocks completion.

For every reviewed task, write `VERIFIED (round N, MODEL)` only when Codex explicitly returns `Task N: VERIFIED`. P0 and P1 block completion. Fix them, rerun affected verification, invalidate every affected verified task, self-check again, and review only pending or invalidated tasks.

P2 does not block completion. Preserve each P2 in the final delivery, and write only a genuinely valuable single follow-up to `NEXT_STEP.md`.

If a finding appears invalid, do not override it locally. Put the counter-evidence into the next review context and continue until Codex verifies the task.

### 6. Skip Paths

With `--no-codex-review`, do not invoke a runner. After self-check, mark completed tasks `SKIPPED (--no-codex-review)` and disclose the opt-out in the final delivery.

If the runner exits `2`, do not write `VERIFIED`. Mark still-unverified completed tasks `SKIPPED (Codex unavailable: concrete reason)` and disclose the primary failure, whether `gpt-5.5` fallback ran, and that Codex did not approve the work.

Normal findings, failed tests, implementation difficulty, missing plan input, or runner exit `64` are not skip conditions.

## Completion Gate

A goal may be declared complete only when self-check passes and every completed task is either:

- `VERIFIED` with no remaining P0/P1; or
- audibly `SKIPPED` by explicit opt-out or genuine Codex unavailability.

Never claim that Codex passed when review was skipped. Never commit, push, create a worktree, or rewrite history unless the user explicitly requested that separate action.
