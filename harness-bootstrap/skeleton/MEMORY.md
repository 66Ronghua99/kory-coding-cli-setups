# Memory

## Stable Notes

- This repository was initialized from the local Harness bootstrap pack.
- `.harness/bootstrap.toml` is the machine-readable bootstrap source of truth.
- Template files under `docs/superpowers/templates/` define the required document shape.

## Working Heuristics

- Keep repository-local docs ahead of implementation drift.
- Encode repeated review feedback into templates, checks, or automation.
- Prefer explicit failure semantics over silent fallback behavior.
