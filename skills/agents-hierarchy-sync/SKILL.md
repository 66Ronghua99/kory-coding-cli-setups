---
name: agents-hierarchy-sync
description: Audit whether a project needs project-root or module-level AGENTS.md files, then generate or update them using a sparse multi-level hierarchy instead of directory-wide sprawl.
---

# Agents Hierarchy Sync

## Goal

Design or maintain a sparse multi-level `AGENTS.md` hierarchy for a project:
- user-level rules stay global
- project-level docs explain the whole repo
- module-level docs exist only where they add real value

## When to Use

- A new project has no root `AGENTS.md`
- A project became too large for one root doc
- The module structure changed and local context docs are stale
- The user asks whether a directory should get its own `AGENTS.md`

## Workflow

1. Read current context
   - user-level `AGENTS.md`
   - project-root `AGENTS.md` if present
   - `PROGRESS.md`
   - `MEMORY.md`
   - `NEXT_STEP.md`
   - active `.plan` docs if relevant
2. Scan repository structure
   - identify top-level apps, packages, services, or major modules
   - locate independent entry points and shared contracts
3. Decide hierarchy
   - keep user-level only
   - add project-root `AGENTS.md`
   - add selected module-level `AGENTS.md`
4. Generate or update docs
   - keep content concise
   - avoid duplicating global rules
   - focus on ownership, entry points, pitfalls, and verification
5. Sync back
   - update project root docs if structure changed
   - note the decision in `.plan` or `MEMORY.md` if it affects future work

## Decision Rule

Add a module-level `AGENTS.md` only if the directory satisfies at least two:
- independent responsibility boundary
- independent runtime or entry point
- high change frequency across tasks
- easy-to-miss local pitfalls
- cross-module coordination cost

## Recommended Templates

### Project Root `AGENTS.md`
- Project Overview
- Directory Map
- Read First
- Key Flows
- Module Boundaries
- Quality Gates
- Related Docs

### Module `AGENTS.md`
- Purpose
- Ownership Boundary
- Entry Points
- Key Files
- Common Pitfalls
- How To Verify Changes

## Output Contract

Return sections in this order:
1. `Repository Structure Snapshot`
2. `Recommended AGENTS Hierarchy`
3. `Files To Create Or Update`
4. `Draft Content Outline`
5. `Doc Sync Notes`

## Rules

- Prefer fewer `AGENTS.md` files with higher signal.
- Do not create module docs for every folder.
- Do not duplicate user-level policy inside project or module docs.
- If unsure, recommend no new module doc and state why.
