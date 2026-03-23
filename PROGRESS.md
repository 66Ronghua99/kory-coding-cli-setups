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

## In Progress

- Capture fresh clone/update verification evidence for the PowerShell path after the local Git-for-Windows fixture-remote issue is isolated

## Pending

- Run the full PowerShell verification flow on a Windows machine where local fixture remotes can `push` and `clone`
- Declare repository lint/test invariants in docs
