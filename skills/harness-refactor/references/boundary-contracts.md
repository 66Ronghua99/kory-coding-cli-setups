# Boundary Contracts

`harness:refactor` is one part of the governance-only Harness split. Keep these ownership boundaries explicit so architecture review does not swallow every adjacent concern.

## Skill Ownership Split

- `harness:doc-health` owns repository truth and pointer consistency, including stale architecture docs, spec-plan-evidence drift, and mismatched status or route pointers.
- `harness:lint-test-design` owns lint/test invariant design, rollout policy, and the decision to convert recurring review issues into hard boundaries.
- `harness:refactor` owns architecture drift findings and refactor guidance, especially when maintainability, boundary integrity, workflow clarity, or future agent comprehension is degrading even though normal checks still pass.

## Required Routing Rules

- If a refactor review finds stale, missing, or contradictory architecture truth, route that follow-up back through `harness:doc-health` rather than resolving it as an inline documentation audit.
- If the repository cannot state its layer model, folder roles, or allowed boundary crossings, report that missing model explicitly instead of guessing one.
- If repeated architecture findings should become enforceable hard gates, route that follow-up into `harness:lint-test-design` rather than inventing lint/test policy here.
- If the problem is still primarily about architecture drift in code or workflow shape, keep it inside `harness:refactor` even when docs and lint/test surfaces already exist.

## Practical Reading

Use `harness:refactor` to answer: "What architectural drift is happening, why does it matter, and what focused cleanup should happen next?"

Use `harness:doc-health` to answer: "Do the repository's declared truths, pointers, statuses, and evidence still agree?"

Use `harness:lint-test-design` to answer: "Which repeated architecture findings should graduate into lint or test enforcement?"
