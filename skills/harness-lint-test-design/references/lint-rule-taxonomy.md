# Lint Rule Taxonomy

Use lint for invariants that can be checked from repository structure without executing the system.

## Common Families

- top-level allowlists and ambiguous-folder bans
- layer direction and anti-cycle rules
- canonical-owner entrypoint rules
- singleton-owner path bans
- deep-import and barrel-boundary rules
- file-role placement and suffix or naming rules
- infrastructure-only adapter entrypoints
- file, function, or complexity budgets

## Typical Questions

- Is this file in the only allowed home for its role?
- Is this path the canonical owner, or did a second assembly or lifecycle owner appear?
- Does this module import only permitted layers or local roles?
- Did the repository reintroduce an ambiguous bucket such as `runtime/`, `shared/`, or `helpers/` without approval?
- Can the failure message name the forbidden edge and the allowed owner clearly enough for the next agent to self-correct?

Lint should prove the stable graph. If current code truth still needs a temporary escape hatch, record it in the exception ledger instead of weakening the target model.
