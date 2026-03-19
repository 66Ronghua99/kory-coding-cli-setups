---
name: verification-loop
description: Standardize delivery checks after implementation by collecting build, type, test, and review evidence into one release-readiness summary.
---

# Verification Loop

## Goal

Confirm that a change is actually ready to hand off, not merely "looks done".

## When to Use

- After implementing a feature or fix
- Before closing a stage in `.plan`
- Before updating `DONE` status with confidence

## Verification Sequence

1. Read the change scope
   - `PROGRESS.md`
   - `NEXT_STEP.md`
   - active `.plan` checklist
   - current git diff
2. Run project gates if available
   - `npm run typecheck`
   - `npm run build`
   - language or repo-specific tests
3. Review evidence
   - changed files
   - output artifacts
   - logs or screenshots if applicable
4. Run review pass
   - correctness
   - regression risk
   - missing tests
   - security concerns
5. Decide readiness
   - ready
   - not ready
   - ready with explicit residual risk

## Output Contract

Return sections in this order:
1. `Scope Under Verification`
2. `Quality Gate Results`
3. `Evidence Review`
4. `Open Risks`
5. `Release Readiness`

## Rules

- If a required command does not exist, state that explicitly.
- If a quality gate fails, do not declare completion.
- Tie every readiness claim to evidence, not intuition.
