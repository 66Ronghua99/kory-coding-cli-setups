# Evidence Verified Claims Template

Use this pattern when writing delivery evidence that verifies a plan.

## Verified Claims

```yaml
schema: harness-verified-claims.v1
verified_claims:
  - claim_id: evidence.example.frozen-contracts
    plan_path: docs/superpowers/plans/example-plan.md
    plan_claim_id: plan.example.frozen-contracts
    plan_hash: replace-with-current-hash
    artifacts:
      - artifacts/example/log.txt
```
