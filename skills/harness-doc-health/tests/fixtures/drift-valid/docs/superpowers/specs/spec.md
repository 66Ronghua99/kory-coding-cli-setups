---
doc_type: spec
status: active
supersedes: []
related: []
---

# Example Drift Spec

## Frozen Contracts
<!-- drift_anchor: frozen_contracts -->

- The plan must track the current frozen contracts section hash.
- Evidence must stay aligned with the current execution truth.

## Acceptance
<!-- drift_anchor: acceptance -->

- `--phase drift` should return exit code `0` for a fresh chain.
- Stale hashes should block completion.
