# Spec And Plan Truth Template

Use this pattern when refreshing a spec or plan chain.

## Frozen Contracts
<!-- drift_anchor: frozen_contracts -->

- [stable contract 1]
- [stable contract 2]

## Acceptance
<!-- drift_anchor: acceptance -->

- [acceptance signal 1]
- [acceptance signal 2]

## Execution Truth

```yaml
schema: harness-execution-truth.v1
claims:
  - claim_id: plan.example.frozen-contracts
    source_spec: docs/superpowers/specs/example-spec.md
    source_anchor: frozen_contracts
    source_hash: replace-with-current-hash
```
