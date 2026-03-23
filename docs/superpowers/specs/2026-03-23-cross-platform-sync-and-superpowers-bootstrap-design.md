---
doc_type: spec
status: approved
supersedes: []
related: []
---

# Cross-Platform Sync And Superpowers Bootstrap Spec

## Problem

The repository currently provides a Bash-only sync script, [`sync-agent-links.sh`](/Users/cory/.coding-cli/sync-agent-links.sh), that works for macOS-style environments but does not support Windows PowerShell. It also does not treat the local [`superpowers`](/Users/cory/.coding-cli/superpowers) repository as a first-class dependency of the sync flow: clone/update behavior is missing from the one-command setup path, and the repository-local [`skills/superpowers`](/Users/cory/.coding-cli/skills/superpowers) link is not guaranteed to be created or refreshed by the sync flow.

As a result, setting up a fresh Windows environment requires manual steps, and even on macOS the one-command sync path can leave `superpowers` out of date or unavailable to the downstream agent clients.

## Success

- Running the macOS/Linux sync script can ensure the local `superpowers` repository exists, optionally update it, ensure the repository-local `skills/superpowers` link points at `superpowers/skills`, and then sync the existing whole-directory `skills` mapping to downstream clients.
- Running a new PowerShell sync script can perform the equivalent setup for Windows under hidden agent directories rooted at `%USERPROFILE%`, including the same namespace link behavior.
- The sync flow remains explicit about destructive situations: conflicting files are backed up before replacement, and invalid repository states fail with actionable errors instead of silent fallback.

## Out Of Scope

- Replacing the current shell-based sync approach with a Node, Python, or other unified runtime.
- Refactoring every downstream client integration beyond the directories already managed by the existing sync script family.

## Critical Paths

1. Existing repository root on macOS/Linux:
   ensure the local `superpowers` checkout exists, optionally update it, ensure the repository-local `skills/superpowers` link is correct, then sync repository docs/config and the existing whole-directory `skills` links to downstream clients.
2. Fresh or existing Windows user profile root:
   treat `%USERPROFILE%` as the hidden-directory root for downstream clients, clone or update `superpowers` at the chosen project root, ensure the repository-local `skills/superpowers` link is correct, then sync the same repository docs/config targets and whole-directory `skills` links as the Bash flow.

## Frozen Contracts
<!-- drift_anchor: frozen_contracts -->

- The canonical `superpowers` checkout lives at the project root as [`superpowers`](/Users/cory/.coding-cli/superpowers), not inside the `skills` directory.
- The exposure model follows the repository's current sync pattern: downstream clients receive a whole-directory link to the repository-local [`skills`](/Users/cory/.coding-cli/skills) tree, and `superpowers` is made visible by ensuring [`skills/superpowers`](/Users/cory/.coding-cli/skills/superpowers) points at [`superpowers/skills`](/Users/cory/.coding-cli/superpowers/skills).
- Both sync scripts expose the same high-level responsibilities: sync core repo links, ensure `superpowers` exists, optionally update `superpowers`, and ensure the repository-local `skills/superpowers` directory link exists before syncing downstream clients.
- Windows support targets hidden agent directories under `%USERPROFILE%`, including `.codex`, `.claude`, `.gemini`, `.copilot`, and `.agents`.
- For Codex in this repository, the existing skills sync target remains the current `.codex/skills/skills` mapping; `superpowers` appears there through the repository-local `skills/superpowers` link.
- Windows intentionally does **not** sync `statusline-command.sh`; that file remains Bash-only unless a Windows-native statusline script is added in a separate change.
- Existing conflicting files or directories at sync targets are backed up before replacement rather than overwritten in place.
- Re-running either script against already-correct links is a no-op for those targets.

## Architecture Invariants

- The repository's own [`skills`](/Users/cory/.coding-cli/skills) and [`superpowers/skills`](/Users/cory/.coding-cli/superpowers/skills) remain separate sources; the sync scripts wire them together only through the repository-local `skills/superpowers` link.
- Downstream clients continue to receive the existing whole-directory `skills` mapping; the sync change must not require a new per-skill layout in client homes.
- `superpowers` bootstrap logic is shared conceptually across both scripts, but each platform keeps a native implementation rather than introducing a new runtime dependency.
- Update behavior is explicit and mode-driven; the default sync path may clone a missing `superpowers` checkout but must not silently contact the network for an existing checkout unless update mode was requested.
- Update mode uses explicit fetch plus fast-forward semantics and must not create merge commits.

## Failure Policy

- If `git` is unavailable, the scripts fail immediately with a clear message when clone/update work is required.
- If the local `superpowers` path does not exist, the scripts clone from the official `https://github.com/obra/superpowers.git` remote into the configured project-root `superpowers` directory.
- If the local `superpowers` path exists but is not a git repository, the scripts fail and ask the user to repair or remove it manually instead of guessing.
- If update mode is requested and the `superpowers` checkout has uncommitted changes, a detached `HEAD`, or cannot fast-forward cleanly from its configured upstream, the scripts fail without mutating the checkout.
- If update mode is requested and the checkout has no configured upstream branch, the scripts fail with a message that names the checkout path and missing branch tracking state.
- If a target path cannot be backed up or linked, the scripts stop with a concrete path-specific error.
- If Windows symbolic-link creation is unavailable, the PowerShell script must fall back to hard links for file targets on the same volume and directory junctions for directory targets such as `skills/superpowers` and downstream `skills` links; if the required Windows-native fallback also fails, the script stops with the underlying error.
- Allowed fallback:
  if `superpowers` already exists and no update mode was requested, the scripts reuse the local checkout without contacting the network, even if its remote is unavailable.
  if a target already points to the correct source, the scripts leave it in place without backup or replacement.

## Acceptance
<!-- drift_anchor: acceptance -->

- Bash script verification covers:
  missing `superpowers` clone, repository-local `skills/superpowers` link creation, existing clean checkout with no update requested, update mode fast-forward success, conflicting target backup, and idempotent rerun when links are already correct.
- PowerShell script verification covers the equivalent Windows hidden-directory cases plus successful `superpowers` junction creation and downstream file-target sync semantics when hard-link fallback is used.
- Error-path verification covers:
  missing `git`, existing non-git `superpowers` path, dirty checkout during update mode, and update failure when fast-forward is not possible.
- Repository docs are updated so a user can discover the one-command sync flow, the optional `superpowers` update mode, the hidden-directory target layout, and the Windows PowerShell entrypoint without reading the script source.

## Deferred Decisions

- Whether `superpowers` update mode should be named `--update-superpowers`, `--pull`, or similar in each script.
- Whether other downstream clients beyond the currently managed set should gain a `superpowers` namespace entry in this same change or a later follow-up.
