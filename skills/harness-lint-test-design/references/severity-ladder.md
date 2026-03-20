# Severity Ladder

Use rollout phases deliberately.

- `seeded`: rule documented but not yet enforced in tooling
- `warn`: drift is visible but does not block delivery yet
- `error`: drift is blocking and must be fixed before completion

Recommended practice:

- boundary rules start at `error` when feasible
- budget rules may begin at `warn` and tighten as the codebase stabilizes
- promotion criteria should be explicit in repository docs
