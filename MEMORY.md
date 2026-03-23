# Memory

## Stable Notes

- This repository was initialized from the local Harness bootstrap pack.
- `.harness/bootstrap.toml` is the machine-readable bootstrap source of truth.
- Template files under `docs/superpowers/templates/` define the required document shape.
- Harness skills define governance standards; Superpowers drives workflow execution.
- `harness:doc-health` owns repository truth and pointer consistency.
- `harness:lint-test-design` owns lint/test invariant and hardgate design.
- `harness:refactor` owns architecture-drift review and refactor governance.
- The shared `skills` directory remains the downstream sync unit for agent homes; `superpowers` is exposed by keeping [`skills/superpowers`](/Users/cory/.coding-cli/skills/superpowers) pointed at [`superpowers/skills`](/Users/cory/.coding-cli/superpowers/skills).
- `sync-agent-links.sh` is the macOS/Linux source of truth for the target mapping, and [`sync-agent-links.ps1`](/Users/cory/.coding-cli/sync-agent-links.ps1) mirrors that behavior for Windows hidden directories under `%USERPROFILE%`.
- The local regression harness can point `superpowers` clone operations at a fixture remote through `SUPERPOWERS_REMOTE_URL`, which keeps shell tests offline and repeatable.

## Working Heuristics

- Keep repository-local docs ahead of implementation drift.
- Encode repeated review feedback into templates, lint, tests, or recurring refactor work.
- Prefer explicit failure semantics over silent fallback behavior.
- Route stale docs to `harness:doc-health`, enforceable recurring issues to `harness:lint-test-design`, and architecture erosion to `harness:refactor`.
- Treat missing `pwsh` on macOS as a verification gap to document, not a reason to claim Windows execution was tested.
