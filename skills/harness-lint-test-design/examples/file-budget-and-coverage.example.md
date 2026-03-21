# File Budget And Coverage Example

Example budget split:

- lint warns when file and function size exceed the current rollout budget
- lint can use different budgets per folder role when orchestration files and pure domain files have different expected shapes
- regression tests cover recently fixed complexity-related defects
- promotion from `warn` to `error` happens only after the discovery baseline is refreshed
