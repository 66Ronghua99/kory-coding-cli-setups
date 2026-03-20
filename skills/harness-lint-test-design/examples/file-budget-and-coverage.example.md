# File Budget And Coverage Example

Example budget split:

- lint warns when file and function size exceed the current rollout budget
- regression tests cover recently fixed complexity-related defects
- promotion from `warn` to `error` happens only after the discovery baseline is refreshed
