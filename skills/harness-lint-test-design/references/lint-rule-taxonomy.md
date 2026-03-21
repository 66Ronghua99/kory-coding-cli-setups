# Lint Rule Taxonomy

Use lint for invariants that can be checked from code structure without executing the system.

## Common Families

- folder classification and file-role placement
- dependency direction and anti-cycle
- deep import bans
- public API boundaries
- infrastructure-only entrypoints
- max file size, function size, depth, params, complexity
- naming and type-shape consistency

## Typical Questions

- Is this file in an allowed directory for its role?
- Does this module import only permitted layers?
- Is this entrypoint the only allowed way to cross the boundary?
- Can the failure message tell the agent exactly where the file should live or which edge is forbidden?

Lint should block structural drift before runtime behavior is even considered.
