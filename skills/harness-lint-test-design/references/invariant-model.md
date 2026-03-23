# Invariant Model

Every important invariant should answer these questions:

1. What is the target layer, ownership, or file-role model?
2. What is the current code truth today?
3. What drift does this invariant prevent?
4. Is the best enforcement point `lint`, `structural test`, `behavior test`, or `docs only`?
5. What failure signal proves the invariant is working?
6. What remediation should the next agent see?
7. Is there a temporary exception ledger entry?
8. What ratchet removes that exception or tightens severity?
9. What plan step and evidence command prove the boundary stayed green?

If the repo cannot answer questions 1 and 2 separately, the model is not ready for hard gates.

If the repo cannot answer questions 5 through 9, the rule is still policy prose, not enforcement design.
