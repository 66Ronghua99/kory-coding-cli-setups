# Verification Evidence

A plan that changes invariants should say how lint, tests, and hardgate evidence will prove both the target model and the current phase.

Good evidence records:

- which commands or checks were run
- which invariants each command was meant to prove
- which exceptions or warnings were expected to remain
- whether a ratchet was promoted, removed, or intentionally deferred
- where logs, reports, or artifacts live

The goal is not verbose logs. The goal is a traceable claim that the repo's hard gates match documented truth and that transitional gaps are explicitly accounted for.
