# Agent Index

## Default Route

1. Load `using-superpowers`.
2. Read `PROGRESS.md`, `NEXT_STEP.md`, `MEMORY.md`, and `.harness/bootstrap.toml`.
3. Route by task type:
   - repository bootstrap or governance baseline setup -> `harness:init`
   - new workflow or behavior design -> `brainstorming`
   - approved multi-step work -> `writing-plans`
   - implementation in this session -> `executing-plans` or `subagent-driven-development`
   - feature or bugfix coding -> `test-driven-development`
   - commit preparation with staged files matching `.harness/bootstrap.toml` `governance.refactor_gate.path_rules` -> `harness:refactor` lightweight `review mode` before `git commit`
   - runtime failure or regression -> `systematic-debugging`
   - repository truth, pointer drift, or stale spec/plan/evidence links -> `harness:doc-health`
   - lint design, test design, invariant design, coverage policy, naming rules, file-role rules, or guardrail design -> `harness:lint-test-design`
   - architecture drift, merge-boundary refactor risk, or proactive refactor governance -> `harness:refactor`
   - delivery review -> `requesting-code-review`
   - completion claim -> `verification-before-completion`
   - branch or worktree wrap-up -> `finishing-a-development-branch`

## Bootstrap Rule

If `.harness/bootstrap.toml` exists, treat it as the machine-readable bootstrap source of truth.

- bootstrap metadata may declare a local commit-time `harness:refactor` gate and strong soft-routing hints for `harness:lint-test-design`
