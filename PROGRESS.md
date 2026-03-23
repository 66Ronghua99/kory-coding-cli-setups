# Progress

## Active Milestone

M1: Ship cross-platform sync scripts with managed `superpowers` bootstrap and update flow.

## Done

- Repository bootstrapped with the governance-only Harness skeleton
- Approved spec written for cross-platform sync and `superpowers` bootstrap
- Implementation plan written for Bash plus PowerShell sync delivery
- Bash sync now bootstraps and optionally updates `superpowers`
- Windows PowerShell sync script added for the same hidden-directory targets
- Windows PowerShell sync now preserves prompt/config file sync on non-admin setups by falling back to hard links for file targets and using Windows-safe backup paths
- `superpowers` is now declared as a formal Git submodule, and the generated `skills/superpowers` link is ignored instead of being tracked

## In Progress

- Align the sync script behavior and tests fully with the new submodule-first `superpowers` model

## Pending

- Decide whether to remove the legacy clone/update flags from the sync scripts now that submodule update is a manual Git action
- Declare repository lint/test invariants in docs
