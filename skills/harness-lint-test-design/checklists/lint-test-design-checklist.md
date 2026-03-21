# Lint-Test Design Checklist

- Freeze the architecture, layer model, and folder classification first.
- If the repo cannot state where each file role belongs, return that as a finding before proposing enforcement.
- Write down each important invariant.
- Decide lint, test, or both for every invariant.
- Include file placement and allowed-edge invariants, not just code-style rules.
- Assign severity and rollout state explicitly.
- Add exception governance or say `none`.
- Define at least one representative pass case and fail case for critical invariants.
- Make failure messages and remediation guidance explicit enough for an agent to self-correct.
- Record how implementation plans and evidence files should cite these boundaries.
