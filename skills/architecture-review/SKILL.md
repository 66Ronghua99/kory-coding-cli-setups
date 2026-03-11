---
name: architecture-review
description: Define module boundaries, ownership, interfaces, migration strategy, and implementation shape after requirements are frozen but before code changes start.
---

# Architecture Review

## Goal

Turn a confirmed requirement into an implementation structure that is small enough to execute and stable enough to maintain.

## Use This Skill When

- The requirement is already frozen.
- The change touches multiple modules, shared contracts, or common configuration.
- The implementation path is still ambiguous even though the user outcome is clear.

## Do Not Use This Skill For

- Initial requirement discovery.
- Pure bugfixes confined to one file.
- Final verification after code changes.

## Workflow

1. Read context in order:
   - `PROGRESS.md`
   - `NEXT_STEP.md`
   - `MEMORY.md`
   - active `.plan` requirement or closed-loop doc
   - relevant code paths
2. Define the implementation boundary:
   - owning module
   - touched modules
   - public contracts
   - migration impact
3. Compare implementation options:
   - preferred option
   - rejected option
   - deferred option if needed
4. Produce a minimal execution shape:
   - file targets
   - contract changes
   - sequencing
   - risks
   - verification points

## Output Contract

Return sections in this order:
1. `Architecture Context`
2. `Boundary and Ownership`
3. `Options and Tradeoffs`
4. `Recommended Shape`
5. `Migration and Risk`
6. `Verification Hooks`

## Rules

- Prefer extending current patterns over introducing a new framework.
- Keep one primary recommendation.
- Name exact files or directories whenever possible.
- Escalate compatibility risks explicitly.
