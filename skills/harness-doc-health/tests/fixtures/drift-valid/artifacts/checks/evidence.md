---
doc_type: evidence
status: active
supersedes: []
related: []
---

# Example Drift Evidence

## Verified Claims

```yaml
schema: harness-verified-claims.v1
verified_claims:
  - claim_id: evidence.example.frozen-contracts
    plan_path: docs/superpowers/plans/plan.md
    plan_claim_id: plan.example.frozen-contracts
    plan_hash: __PLAN_HASH_FROZEN__
    artifacts:
      - artifacts/checks/frozen-contracts.log
  - claim_id: evidence.example.acceptance
    plan_path: docs/superpowers/plans/plan.md
    plan_claim_id: plan.example.acceptance
    plan_hash: __PLAN_HASH_ACCEPTANCE__
    artifacts:
      - artifacts/checks/acceptance.log
```
