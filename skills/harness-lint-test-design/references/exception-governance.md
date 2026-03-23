# Exception Governance

Exceptions are allowed only when they are narrow, temporary, owned, and easier to remove later than to encode into the permanent model today.

## Required Fields

- invariant id
- owner
- exact scope
- current-truth mismatch
- reason
- target phase or milestone
- removal trigger
- ratchet step
- status

## Rules

- If an exception has no exit condition, it is ungoverned debt.
- If an exception changes the target model, it is not an exception; it is a design change.
- If an exception is broad enough to describe a whole layer or folder casually, the underlying model is still too vague.
- Exceptions should shrink over time. Count, scope, or severity should move in one direction only.
