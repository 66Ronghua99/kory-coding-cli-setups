# Invariant Model

Every important repository invariant should answer six questions:

1. What drift does this invariant prevent?
2. Is the best enforcement point lint, tests, or both?
3. What is the rollout severity today?
4. What evidence proves the invariant is working?
5. What exceptions are allowed?
6. What condition removes the exception?

If an invariant cannot answer these questions, it is not ready to become a hard boundary.
