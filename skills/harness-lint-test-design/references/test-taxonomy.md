# Test Taxonomy

Use tests for invariants that require execution, fixtures, or repository-level proofs beyond static import analysis.

## Common Families

- unit tests for local behavior guarantees
- contract tests for narrow adapter or interface seams
- structural tests for ownership, graph, fixture, or repository-shape rules
- integration tests for cross-module behavior
- regression tests for escaped defects and boundary freezes

## Structural Proof Examples

- only one composition root assembles concrete infrastructure
- only one lifecycle owner controls workflow startup and shutdown
- direct-call paths remain hook-free while adapter paths keep hook behavior
- kernel or engine code consumes narrow contracts instead of product-domain objects
- workflow modules stay isolated from one another

Tests should prove not only that the system behaves correctly, but that the intended boundary still exists after the next refactor.
