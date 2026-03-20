# Lint-Test Design Checklist

- Freeze the architecture or module boundary first.
- Write down each important invariant.
- Decide lint, test, or both for every invariant.
- Assign severity and rollout state explicitly.
- Add exception governance or say `none`.
- Define at least one representative pass case and fail case for critical invariants.
- Record how implementation plans and evidence files should cite these boundaries.
