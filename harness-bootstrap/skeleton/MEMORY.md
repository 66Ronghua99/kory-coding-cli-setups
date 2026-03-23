# Memory

## Stable Notes

- This repository was initialized from the local Harness bootstrap pack.
- `.harness/bootstrap.toml` is the machine-readable bootstrap source of truth.
- Template files under `docs/superpowers/templates/` define the required document shape.
- Harness skills define governance standards; Superpowers drives workflow execution.
- `harness:doc-health` owns repository truth and pointer consistency.
- `harness:lint-test-design` owns lint/test invariant and hardgate design.
- `harness:refactor` owns architecture-drift review and refactor governance.

## Working Heuristics

- Keep repository-local docs ahead of implementation drift.
- Encode repeated review feedback into templates, lint, tests, or recurring refactor work.
- Prefer explicit failure semantics over silent fallback behavior.
- Route stale docs to `harness:doc-health`, enforceable recurring issues to `harness:lint-test-design`, and architecture erosion to `harness:refactor`.
