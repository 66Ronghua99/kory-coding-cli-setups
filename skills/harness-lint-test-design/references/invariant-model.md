# Invariant Model

Every important repository invariant should answer these questions:

1. What layer, folder, or file-role model does this invariant assume?
2. What drift does this invariant prevent?
3. Is the best enforcement point lint, structural tests, behavior tests, or a docs-only policy?
4. What is the rollout severity today?
5. What evidence proves the invariant is working?
6. What exceptions are allowed?
7. What condition removes the exception?
8. What remediation should the agent see when this invariant fails?

If the repo cannot answer question 1, the model itself is missing and should be written down before enforcement is proposed.

If an invariant cannot answer the remaining questions, it is not ready to become a hard boundary.
