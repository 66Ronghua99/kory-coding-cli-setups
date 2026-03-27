# harness:refactor Playbook

## What Counts As Drift

Treat these as architecture drift when they start to blur responsibility:

- code for one boundary lives in the wrong folder or layer
- filenames or directory names no longer tell the truth about ownership
- adapters, parsers, or workflow glue leak provider-native or transport-native details inward
- one file begins coordinating state, persistence, retry, and orchestration at once
- generic shared folders start absorbing subsystem-owned code
- abstractions get deeper without making control flow easier to follow

## Severity

- `P0`: unsafe boundary collapse or architecture break
- `P1`: serious drift that materially harms legibility or maintainability
- `P2`: worthwhile cleanup target that should be scheduled
- `P3`: localized improvement or watchlist note

## Action Shapes

Choose the smallest follow-up shape that matches the finding:

- `rename` when the path or filename lies about the role
- `move` when the file belongs in a different ownership boundary
- `split` when one file now mixes unrelated responsibilities
- `boundary test` when the code is probably right but the edge needs proof
- `hardgate candidate` when the same drift is recurring and should become enforceable

## Scope Bounding

- start from the diff, hotspot, or recurring pattern, not a repo-wide sweep
- inspect only directly changed files plus the smallest adjacent boundary surface needed to judge the drift
- do not widen into a subsystem audit unless the hotspot itself is already broad
- if the repo lacks a clear layer or folder-role model, report that missing model instead of inventing one

## When To Promote Into `harness:lint-test-design`

Stay in `harness:refactor` while the finding still needs judgment about whether the boundary itself is healthy.

Promote when the boundary can already be stated as a repository-local rule, such as:

- an import edge that should never appear
- a folder-role rule that can be checked mechanically
- a structural or boundary test that should always pass
- a coverage expectation tied to a moved or normalized path
- a ratchet for a recurring architecture finding

Use `harness:refactor` while the issue still needs judgment. Use `harness:lint-test-design` once the rule is stable enough to encode.

## Compact Examples

1. A provider payload parser moved from an adapter into runtime orchestration. Severity is `P1`, action shape is `move` plus `boundary test`, and the follow-up should promote to `harness:lint-test-design` once the normalized boundary is stable.

2. A workflow-owned classifier appears under `shared/utils/`. Severity is `P2`, action shape is `move`, and the likely proof is a folder-role or file-classification invariant after the move lands.
