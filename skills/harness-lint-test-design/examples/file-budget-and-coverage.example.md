# File Budget And Coverage Example

Example proof split:

- new or changed executable code must reach `100%` relevant line and branch coverage unless the exception ledger records a narrow temporary gap
- whole-repo coverage may start below `100%`, but baseline coverage, warning counts, and exception counts only ratchet in one direction
- uncovered code is classified as legacy debt, pending deletion, generated output, approved exception, or intentionally deferred docs-only proof
- lint warns or fails when file and function size exceed the current rollout budget
- lint budgets may differ by file role, but every non-default budget needs owner, reason, and removal trigger
- structural tests prove ownership or boundary rules that coverage cannot prove, such as singleton assembly ownership or a narrow engine/application split
- promotion from `warn` to `error` happens through a named ratchet trigger, not by informal hope
