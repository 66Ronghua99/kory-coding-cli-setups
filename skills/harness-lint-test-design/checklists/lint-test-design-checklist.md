# Lint-Test Design Checklist

- Freeze the target layer model, file-role model, and canonical ownership model first.
- Record the current code truth separately from the target state.
- Name the transition gap explicitly before proposing new hard gates.
- If the repo cannot say where each file role belongs, return that as a blocking finding.
- Identify singleton owners such as composition roots, lifecycle owners, or canonical adapter entrypoints.
- Define the changed-code coverage contract and the whole-repo ratchet policy.
- Classify uncovered code explicitly as legacy debt, pending deletion, generated output, approved exception, or docs-only deferred proof.
- Write down each important invariant.
- Decide `lint`, `structural test`, `behavior test`, or `docs only` for every invariant.
- Separate steady-state rules from transitional exceptions.
- Add owner, exact scope, reason, target phase, removal trigger, and ratchet step for every exception.
- Include path, naming, suffix, barrel, and ambiguous-folder semantics when they affect agent comprehension.
- Produce a matrix for invariants, proofs, exceptions, and ratchets rather than prose only.
- Define at least one representative pass case and fail case for critical invariants.
- Make failure messages and remediation guidance explicit enough for an agent to self-correct.
- Ensure docs, lint, tests, and hardgate outputs all describe the same current truth.
- Record how plans and verification evidence should cite the resulting hard gates.
