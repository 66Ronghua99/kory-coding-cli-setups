# Verification Evidence

A plan that changes invariants should say how lint/test evidence will be produced.

Good evidence usually records:

- which commands or checks were run
- what invariants they were meant to prove
- whether the result was blocking or advisory
- where artifacts or logs live

The goal is not verbose logs. The goal is a traceable claim that the designed boundary was actually exercised.
