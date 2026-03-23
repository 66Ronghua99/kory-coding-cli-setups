# Governance Follow-Up Example

Scope: `runtime/`, `adapters/`, and `evaluation/` for the agent execution subsystem after three similar review findings about boundary leakage.

Severity summary: no active `P0`; one `P1` containment target, two `P2` cleanup targets, and one `P3` watchlist item.

Subsystem debt map

- `P1` Boundary leak: `runtime/` and `evaluation/` both parse provider-native payloads that should stop at adapter edges.
- `P2` Ownership collapse: `runtime/session.ts` coordinates retries, trace persistence, and knowledge cache writes in one file.
- `P2` Surface drift: evaluation code reaches into runtime internals instead of consuming a stable workflow event interface.
- `P2` Placement drift: workflow-owned classifiers and caches are accumulating under `shared/` even though they depend on runtime-only concepts.
- `P2` Naming drift: helper filenames around trace utilities no longer communicate which ones are runtime-only versus cross-cutting.

Refactor targets

1. Re-center provider payload normalization inside adapters and expose one normalized event shape to runtime and evaluation layers.
2. Split `runtime/session.ts` into session state, trace emission, and knowledge access seams.
3. Replace direct evaluation-to-runtime internal reads with a narrow workflow event contract.
4. Move runtime-owned helpers out of `shared/` and publish a folder-role map that explains what belongs there.
5. Rename trace helpers so filenames reveal whether they are runtime-owned or genuinely shared.

Sequencing

1. Contain provider payload parsing first so boundary drift stops spreading.
2. Split session ownership next because it currently blocks clean event boundaries.
3. Re-home runtime-owned helpers so folder placement matches file responsibility.
4. Rename misleading helpers so path semantics stop lying about ownership.
5. Add repository-local invariants only after the new seams exist and the subsystem shape is stable.

Follow-up plan artifact: Yes. Create a repository-local refactor plan artifact because the cleanup spans multiple directories, needs sequencing, and should leave evidence instead of living in scattered review comments.

Required `harness:doc-health` follow-up: Yes. The current subsystem notes still claim adapters normalize all provider payloads before runtime code sees them, and the repo does not yet record the folder-role rule for `shared/`, which is stale or missing architecture truth.

Required `harness:lint-test-design` follow-up: Yes, after targets 1 and 4 land. Repeated provider-shape leakage is enforceable with a lint import boundary and a structural test that runtime code only consumes normalized workflow events; repeated shared-folder misuse is enforceable with file-classification and allowed-edge invariants.

Proof expectations: the follow-up plan should name which boundaries gain structural tests, which moved files must reach full changed-code coverage, and which naming or file-role rules should become hardgate candidates once the cleanup stabilizes.
