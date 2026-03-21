# Layered Boundaries Example

Canonical model:

- `domain/` defines business rules and cannot import `infrastructure/`
- `application/` may orchestrate `domain/` and depend on declared ports
- `infrastructure/` implements ports and adapters
- `interfaces/` owns transport or UI entrypoints only

Example invariant split:

- lint blocks `domain/` -> `infrastructure/` reverse imports
- lint blocks adapter files from living outside `infrastructure/`
- structural test proves no deep imports bypass the public API surface
- structural test proves files under `interfaces/` do not become shared utility sinks
- integration test proves the public entrypoint still composes correctly

Escalation rule:

- if reviewers repeatedly say "this file is in the wrong folder" or "runtime should not import this layer directly," that is a hardgate candidate, not just a style note
