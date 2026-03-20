# Layered Boundaries Example

Example invariant split:

- lint blocks domain -> infrastructure reverse imports
- structural test proves no deep imports bypass the public API surface
- integration test proves the public entrypoint still composes correctly
