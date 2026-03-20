# Lint Rule Taxonomy

Use lint for invariants that can be checked from code structure without executing the system.

## Common Families

- dependency direction and anti-cycle
- deep import bans
- public API boundaries
- infrastructure-only entrypoints
- max file size, function size, depth, params, complexity
- naming and type-shape consistency

Lint should block architectural drift before runtime behavior is even considered.
