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
- Bash and PowerShell sync scripts now require an initialized `superpowers` submodule and no longer perform clone/update work themselves

## In Progress

- Capture fresh Bash-side verification evidence for the simplified submodule-only sync flow in an environment where `bash` can launch successfully

## Pending

- Declare repository lint/test invariants in docs
