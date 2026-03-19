---
doc_type: plan
status: active
implements:
  - docs/superpowers/specs/spec.md
verified_by:
  - artifacts/checks/evidence.md
supersedes: []
related: []
---

# Example Drift Plan

## Execution Truth

```yaml
schema: harness-execution-truth.v1
claims:
  - claim_id: plan.example.frozen-contracts
    source_spec: docs/superpowers/specs/spec.md
    source_anchor: frozen_contracts
    source_hash: __FROZEN_HASH__
  - claim_id: plan.example.acceptance
    source_spec: docs/superpowers/specs/spec.md
    source_anchor: acceptance
    source_hash: __ACCEPTANCE_HASH__
```
