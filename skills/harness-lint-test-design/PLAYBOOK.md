# harness:lint-test-design Playbook

Use this file when the default `SKILL.md` is not enough to make the enforcement choice.

## Choose The Proof

- `lint` when the rule is static, stable, and easy to describe as a path, placement, naming, or edge ban.
- `structural test` when the important fact is ownership shape, singleton reachability, shell-only assembly, or another graph-like boundary.
- `behavior test` when the risk is runtime semantics, adapter behavior, or user-visible regression.
- `coverage expectation` when changed code needs proof and the issue is not yet a static or structural invariant.
- `exception ledger` when the mismatch is real, narrow, owned, and on a removal path.

If the question is "what belongs where?", start with `lint` or a structural test. If the question is "does it do the right thing?", start with a behavior test. If the question is "is this code still honestly transitional?", start with an exception ledger plus a ratchet.

## Exception Governance

Keep exceptions short-lived and explicit:

- owner
- exact scope
- reason for the exception
- exit path
- ratchet trigger

Do not use exception ledger entries to hide a broken target model. If the same exception appears more than once, either promote it into `lint` or a structural test, or narrow the transition so the entry can be removed.

## Ratchet Guidance

- Ratchets only tighten toward the target state.
- A ratchet should describe what gets removed, what gets promoted, and when the ledger entry expires.
- Never widen the target model just to match current drift.
- Prefer one small ratchet per recurring issue instead of a broad policy that nobody can explain.

## Promotion Examples

1. A recurring review comment says only the shell should own concrete assembly. Promote that from note-taking into a structural test, then add a lint rule for the edge if the shape becomes stable.
2. A repeated "changed code lacks proof" finding keeps showing up for the same package. Promote it into a coverage expectation, and if the package is a long-lived architecture seam, add an exception ledger entry with a removal trigger while the proof is being built.
