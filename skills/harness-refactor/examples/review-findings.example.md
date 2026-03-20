# Review Findings Example

Context: PR moves provider response parsing from `adapters/provider-openai.ts` into `runtime/run-loop.ts` and adds trace writes inside the retry helper.

Finding 1

- Title: Raw provider payload parsing now lives inside the run loop
- Severity: `P1`
- Affected boundary: provider adapter -> workflow orchestration
- Why lint/test may still pass: the same fields are still read, happy-path tests stay green, and no type error appears even though provider-specific shape knowledge moved deeper into runtime code.
- Suggested focused follow-up: move payload normalization back to the adapter, keep the run loop on normalized domain events, and add one boundary test that proves the runtime never reads provider-native fields.
- Route to `harness:lint-test-design`: Yes, if this is a repeated review pattern. Add an invariant that runtime code cannot import provider SDK shapes directly.

Finding 2

- Title: Retry helper now owns trace persistence
- Severity: `P2`
- Affected boundary: core retry logic -> observability sink
- Why lint/test may still pass: retries still succeed and traces still write, so behavior checks pass even while a reusable helper takes on workflow-specific side effects.
- Suggested focused follow-up: inject a trace event hook at the workflow edge and keep retry logic transport-agnostic.
- Route to `harness:lint-test-design`: No, not yet. Fix the hotspot first and only harden it if the same side-effect leak keeps recurring.

Merge guidance: acceptable only with focused follow-up or scope narrowing. Do not widen this PR into a broader cleanup.

Advisory-first note: this finding set is not the merge authority. Repository-local merge policy and blocking decisions still decide whether the PR waits for containment or ships with an explicit defer rationale.

Defer rationale if the `P1` issue is not fixed now: record the owner, the temporary containment choice, the reason merge risk is acceptable, and the exact follow-up path into either the next PR or a tracked refactor item.

Required `harness:doc-health` follow-up: Yes, if the current subsystem notes or testing docs still say provider payload normalization ends at the adapter boundary. Keep that stale architecture truth fix separate from the refactor finding itself.
