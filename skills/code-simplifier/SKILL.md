---
name: code-simplifier
description: Simplify and refine recently modified code for clarity, consistency, and maintainability while preserving exact behavior. Use when the user asks to simplify, clean up, refactor lightly, polish, or review recently touched implementation code without changing functionality, or when a final pass should make code easier to read before handoff.
---

# Code Simplifier

## Overview

Refine code without changing what it does. Focus on recently modified code unless the user explicitly names a broader scope.

Prefer readable, explicit code over compact cleverness. The goal is easier maintenance, not fewer lines.

## Workflow

1. Identify the recently modified code with `git diff`, `git status`, or the files named by the user.
2. Read nearby code and project guidance before editing, including local `AGENTS.md`, style guides, and relevant tests.
3. Look for simplifications that preserve behavior:
   - remove redundant branches, wrappers, variables, or abstractions
   - reduce unnecessary nesting and split overly dense expressions
   - improve names when doing so clarifies intent without broad churn
   - consolidate duplicated logic that is clearly local to the change
   - remove comments that only restate obvious code
   - keep helpful comments that explain non-obvious intent, constraints, or tradeoffs
4. Apply the smallest coherent edits.
5. Verify with the strongest relevant tests, typechecks, builds, or focused smoke checks available.
6. Summarize only meaningful refinements and any verification gaps.

## Guardrails

- Preserve public APIs, data shapes, side effects, timing assumptions, error behavior, and user-visible text unless the user explicitly asks to change them.
- Follow the repository's existing conventions over generic preferences.
- Do not introduce broad fallback behavior, silent defaults, or catch-all error handling to make code look simpler.
- Avoid nested ternaries and dense one-liners for multi-condition logic; prefer clear `if`/`else` chains or `switch` statements where appropriate.
- Do not collapse useful abstractions just to reduce file count or line count.
- Do not widen scope into unrelated files or untouched code unless required by the simplification.
- Do not perform formatting-only churn across files outside the requested or recently touched scope.

## What To Prefer

- Explicit control flow when it makes state or failure modes easier to inspect.
- Local helpers when they remove real duplication or name a meaningful concept.
- Direct code when an abstraction adds indirection without reducing complexity.
- Project-native patterns for imports, component structure, async flow, errors, tests, and naming.
- Behavior-preserving tests or snapshots when a simplification touches logic that could regress.

## Stop Conditions

- Stop and report instead of editing if behavior would need to change to make the code simpler.
- Stop and ask for scope confirmation if the simplification requires touching unrelated modules or public contracts.
- Stop and document the blocker if tests or project commands needed to prove behavior are unavailable.
