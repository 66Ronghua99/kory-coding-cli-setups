# Layered Boundaries Example

Canonical target model:

- `application/shell/` is the only top-level concrete assembly owner
- workflow modules under `application/` own semantics but do not freely assemble infrastructure
- `kernel/` is engine-only and must not absorb product-domain or infrastructure concerns
- `infrastructure/` implements contracts but does not own workflow semantics

Example invariant split:

- lint blocks `kernel -> domain` and `kernel -> infrastructure`
- lint blocks non-shell `application/* -> infrastructure/*`
- lint blocks ambiguous buckets such as revived `runtime/`, `shared/`, or `helpers/`
- structural test proves only one composition root assembles concrete adapters
- structural test proves only one lifecycle owner controls workflow execution
- regression test proves a direct-call path stays hook-free while the adapter path still runs hooks

Transition governance:

- if current code truth still requires one temporary edge, record it as an exception ledger entry with owner, scope, target phase, and removal trigger
- do not widen the permanent architecture model just because one transitional edge still exists
