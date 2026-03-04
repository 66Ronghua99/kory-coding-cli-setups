# CLAUDE.md v2

  ## 0) Priority Order (冲突时按此优先级)
  1. Safety & Data Protection
  2. Correctness & Backward Compatibility
  3. Architecture Quality
  4. Delivery Speed
  5. Documentation Completeness

  ---

  ## 1) Non-Negotiables (硬约束)
  1. Do not code before reading project context files:
     - `PROGRESS.md`
     - `NEXT_STEP.md` (if exists and non-empty)
     - `MEMORY.md` (only relevant sections)
  2. No destructive action without explicit user confirmation.
  3. No secret leakage in code/log/docs.
  4. No delivery without running quality gates.
  5. Every code change must map to a concrete requirement/risk.

  ---

  ## 2) Work Modes
  1. Fast Path (small/local change):
     - Single module, no public contract change, low risk.
     - Direct implement + test + brief summary.
  2. Design Path (required if any condition matches):
     - Cross-module changes
     - New abstraction/layer/protocol
     - Data model or API contract change
     - Security-sensitive path
     - Refactor > 150 LOC or > 3 files

  ---

  ## 3) Required Design Artifacts (Design Path)
  Before coding, produce:
  1. Problem Statement
     - Current pain, constraints, non-goals
  2. Boundary & Ownership
     - Module boundaries, dependency direction, source of truth
  3. Options & Tradeoffs
     - At least 2 options and rejection reason
  4. Migration Plan
     - Incremental steps, compatibility strategy, rollback point
  5. Test Strategy
     - Unit/integration/e2e scope and acceptance criteria

  ---

  ## 4) Engineering Mindset (可复用原则)
  1. Boundary First:
     - Define boundaries/dependencies first, then implementation.
  2. Single Source of Truth:
     - Protocol/model/state must have one authoritative definition.
  3. Make Illegal States Unrepresentable:
     - Use types/validators/policies to prevent invalid states.
  4. Policy as Code:
     - Auth/retry/role rules must be explicit code, not comments.
  5. Side-effect Minimalism:
     - Avoid import-time side effects (I/O, logging setup, global mutation).
  6. Progressive Hardening:
     - First make it work, then make it safe/typed/tested in phases.

  ---

  ## 5) Implementation Rules
  1. Keep responsibilities small:
     - Prefer composable services over god classes.
  2. Refactor trigger:
     - Function > 80 lines or repeated branch logic appears >= 2 times.
  3. Public contract changes require:
     - Version/compatibility note and migration handling.
  4. Prefer deterministic behavior:
     - Structured data over free-form strings for execution-critical paths.

  ---

  ## 6) Quality Gates (must run before handoff)
  1. Lint:
     - `uv run ruff check src tests`
  2. Type:
     - `uv run mypy src`
  3. Tests:
     - `uv run pytest -q`
  4. If any gate fails:
     - Do not claim completion.
     - Report exact failure and mitigation plan.
  5. Similar rules apply to other languages (e.g., javascript)

  ---

  ## 7) Testing Policy
  1. Test intent over test volume:
     - Cover core logic, boundary conditions, failure modes.
  2. Avoid over-mocking:
     - Mock external systems; keep domain behavior real when possible.
  3. Contract-focused tests:
     - Add tests for protocol/schema/policy boundaries.
  4. Regression-first for bugfix:
     - Add failing test first, then fix.

  ---

  ## 8) Logging & Debugging
  1. Structured logs with stable keys:
     - timestamp, level, module, trace/context id, business key
  2. Debug without leaking secrets:
     - Redact token/password/PII by default.
  3. Debug workflow:
     - reproduce -> instrument minimal logs -> identify root cause -> fix -> verify -> clean noisy logs.

  ---

  ## 9) Git & Delivery
  1. Small, isolated commits.
  2. Commit only when user asks explicitly.
  3. Commit message follows Conventional Commits.
  4. For refactor tasks:
     - Separate “mechanical cleanup” and “behavioral change” commits.

  ---

  ## 10) Context Files Update Policy
  1. Update `PROGRESS.md` only when milestone/status changes.
  2. Update `MEMORY.md` only for reusable lessons:
     - root cause
     - fix
     - preventive rule
  3. `NEXT_STEP.md` is execution pointer, not long-form history.

  ---

  ## 11) Definition of Done
  A task is done only if:
  1. Requirement satisfied
  2. Quality gates passed
  3. Risk/compatibility explained
  4. Context docs updated when needed
  5. Clear next-step suggestions provided
