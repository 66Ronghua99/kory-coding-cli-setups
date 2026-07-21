---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

Write comprehensive implementation plans assuming the engineer has zero context for the codebase. Document which files to touch, the interfaces between tasks, the exact implementation steps, and the evidence that proves each deliverable works. Keep plans DRY, focused, and consistent with the repository's own verification policy.

Assume they are a skilled developer, but know almost nothing about our toolset or problem domain. Assume they don't know good test design very well.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."


**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`
- Do not stage or commit `docs/plans`, `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, or `artifacts/`.
- (User preferences for plan location override this default)

## Scope Check

If the spec covers multiple independent subsystems, it should have been broken into sub-project specs during brainstorming. If it wasn't, suggest breaking this into separate plans — one per subsystem. Each plan should produce working, testable software on its own.

## File Structure

Before defining tasks, map out which files will be created or modified and what each one is responsible for. This is where decomposition decisions get locked in.

- Design units with clear boundaries and well-defined interfaces. Each file should have one clear responsibility.
- You reason best about code you can hold in context at once, and your edits are more reliable when files are focused. Prefer smaller, focused files over large ones that do too much.
- Files that change together should live together. Split by responsibility, not by technical layer.
- In existing codebases, follow established patterns. If the codebase uses large files, don't unilaterally restructure - but if a file you're modifying has grown unwieldy, including a split in the plan is reasonable.

This structure informs the task decomposition. Each task should produce self-contained changes that make sense independently.

## Task Right-Sizing

A task is the smallest unit that carries its own test cycle and is worth a
fresh reviewer's gate. When drawing task boundaries: fold setup,
configuration, scaffolding, and documentation steps into the task whose
deliverable needs them; split only where a reviewer could meaningfully
reject one task while approving its neighbor. Each task ends with an
independently testable deliverable.

## Bite-Sized Task Granularity

**Each step is one concrete action:**
- Define the observable result and the evidence required by the repository.
- Add or update a test only when the changed contract is not already covered.
- Implement the smallest complete change.
- Run the exact verification command and record the expected result.

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For agentic workers:** Execute this plan task-by-task using the current harness. Steps use checkbox (`- [ ]`) syntax for tracking; use native subagents only when tasks are genuinely independent.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

## Global Constraints

[The spec's project-wide requirements — version floors, dependency limits,
naming and copy rules, platform requirements — one line each, with exact
values copied verbatim from the spec. Every task's requirements implicitly
include this section.]

---
```

## Task Structure

````markdown
### Task N: [Component Name]

**Execution:** [ ] complete
**Codex verification:** PENDING

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Interfaces:**
- Consumes: [what this task uses from earlier tasks — exact signatures]
- Produces: [what later tasks rely on — exact function names, parameter
  and return types. A task's implementer sees only their own task; this
  block is how they learn the names and types neighboring tasks use.]

- [ ] **Step 1: Define the observable result**

State the behavior, boundary, or invariant this task must establish and the evidence that will prove it.

- [ ] **Step 2: Add contract coverage when needed**

Reuse existing tests when they cover the changed contract. Add a focused test only when the task introduces new observable behavior.

- [ ] **Step 3: Implement the complete change**

Show the exact code or configuration required. Do not leave placeholders, compatibility shims, or deferred work.

- [ ] **Step 4: Verify the changed path**

Run the narrow command or smoke scenario that exercises the deliverable and state the expected successful output.

## Execution and Review State

Every task starts with `**Execution:** [ ] complete` and `**Codex verification:** PENDING`. The executing agent changes execution to `[x]` only after task verification. Codex verification is written by the coding agent from an explicit reviewer result and may become `VERIFIED`, `PENDING (invalidated ...)`, or `SKIPPED` according to the approved plan-execution policy. Do not automatically invoke `executing-plans`.

## No Placeholders

Every step must contain the actual content an engineer needs. These are **plan failures** — never write them:
- "TBD", "TODO", "implement later", "fill in details"
- "Add appropriate error handling" / "add validation" / "handle edge cases"
- "Write tests for the above" (without actual test code)
- "Similar to Task N" (repeat the code — the engineer may be reading tasks out of order)
- Steps that describe what to do without showing how (code blocks required for code steps)
- References to types, functions, or methods not defined in any task

## Remember
- Exact file paths always
- Complete code in every step — if a step changes code, show the code
- Exact commands with expected output
- DRY, YAGNI, repository-native verification

## Self-Review

After writing the complete plan, look at the spec with fresh eyes and check the plan against it. This is a checklist you run yourself — not a subagent dispatch.

**1. Spec coverage:** Skim each section/requirement in the spec. Can you point to a task that implements it? List any gaps.

**2. Placeholder scan:** Search your plan for red flags — any of the patterns from the "No Placeholders" section above. Fix them.

**3. Type consistency:** Do the types, method signatures, and property names you used in later tasks match what you defined in earlier tasks? A function called `clearLayers()` in Task 3 but `clearFullLayers()` in Task 7 is a bug.

If you find issues, fix them inline. No need to re-review — just fix and move on. If you find a spec requirement with no task, add the task.

## Execution Handoff

After saving the plan, continue with the safest execution mode supported by the current harness:

- Use native subagents only when tasks are genuinely independent and their interfaces are already frozen.
- Otherwise execute the plan inline, one task at a time, verifying each deliverable before moving on.
- Do not require another named skill, plugin, worktree helper, or commit workflow.
- Do not automatically invoke `executing-plans`.
- If both modes are equivalent, default to inline execution instead of asking the user to choose.
