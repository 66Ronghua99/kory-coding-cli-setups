---
doc_type: spec
status: approved
supersedes: []
related: []
---

# Cross-Platform Sync And Superpowers Bootstrap Spec

## Problem

The repository now has Bash and PowerShell sync scripts, but the Git model around [`superpowers`](/Users/cory/.coding-cli/superpowers) and [`skills/superpowers`](/Users/cory/.coding-cli/skills/superpowers) was inconsistent. `superpowers` should be consumed as an external repository through Git submodules, while `skills/superpowers` should be a generated local link that exposes `superpowers/skills` through the existing whole-directory `skills` sync model.

Without formal submodule metadata and Git ignore rules, recursive clone/init behavior is unreliable and the generated `skills/superpowers` link can appear as a tracked file change instead of a local sync artifact.

## Success

- A fresh clone can fetch [`superpowers`](/Users/cory/.coding-cli/superpowers) through `git clone --recurse-submodules` or `git submodule update --init --recursive`.
- Running the macOS/Linux or Windows sync scripts can ensure the repository-local `skills/superpowers` link points at `superpowers/skills`, then sync the existing whole-directory `skills` mapping to downstream clients.
- The generated `skills/superpowers` link remains out of Git tracking so local sync runs do not dirty the parent repository.
- The sync flow remains explicit about destructive situations: conflicting files are backed up before replacement, and invalid repository states fail with actionable errors instead of silent fallback.

## Out Of Scope

- Replacing the current shell-based sync approach with a Node, Python, or other unified runtime.
- Refactoring every downstream client integration beyond the directories already managed by the existing sync script family.

## Critical Paths

1. Fresh or existing repository clone:
   initialize the `superpowers` submodule, ensure the repository-local `skills/superpowers` link is correct, then sync repository docs/config and the existing whole-directory `skills` links to downstream clients.
2. Fresh or existing Windows user profile root:
   treat `%USERPROFILE%` as the hidden-directory root for downstream clients, ensure the local `superpowers` submodule is initialized, ensure the repository-local `skills/superpowers` link is correct, then sync the same repository docs/config targets and whole-directory `skills` links as the Bash flow.

## Frozen Contracts
<!-- drift_anchor: frozen_contracts -->

- The canonical `superpowers` checkout lives at the project root as [`superpowers`](/Users/cory/.coding-cli/superpowers), not inside the `skills` directory.
- `superpowers` is a Git submodule rooted at the project path above.
- The exposure model follows the repository's current sync pattern: downstream clients receive a whole-directory link to the repository-local [`skills`](/Users/cory/.coding-cli/skills) tree, and `superpowers` is made visible by ensuring [`skills/superpowers`](/Users/cory/.coding-cli/skills/superpowers) points at [`superpowers/skills`](/Users/cory/.coding-cli/superpowers/skills).
- `skills/superpowers` is a generated local link and must not be tracked in the parent repository.
- Both sync scripts expose the same high-level responsibilities: sync core repo links and ensure the repository-local `skills/superpowers` directory link exists before syncing downstream clients.
- Windows support targets hidden agent directories under `%USERPROFILE%`, including `.codex`, `.claude`, `.gemini`, `.copilot`, and `.agents`.
- For Codex in this repository, the existing skills sync target remains the current `.codex/skills/skills` mapping; `superpowers` appears there through the repository-local `skills/superpowers` link.
- Windows intentionally does **not** sync `statusline-command.sh`; that file remains Bash-only unless a Windows-native statusline script is added in a separate change.
- Existing conflicting files or directories at sync targets are backed up before replacement rather than overwritten in place.
- Re-running either script against already-correct links is a no-op for those targets.

## Architecture Invariants

- The repository's own [`skills`](/Users/cory/.coding-cli/skills) and [`superpowers/skills`](/Users/cory/.coding-cli/superpowers/skills) remain separate sources; the sync scripts wire them together only through the repository-local `skills/superpowers` link.
- Downstream clients continue to receive the existing whole-directory `skills` mapping; the sync change must not require a new per-skill layout in client homes.
- `superpowers` lifecycle is governed by Git submodule commands rather than ad-hoc sync-script clone logic.
- Sync scripts should not require a new runtime dependency beyond the platform shell and filesystem link support.

## Failure Policy

- If the local `superpowers` path does not exist, the user must initialize the submodule instead of relying on the sync scripts to clone it.
- If the local `superpowers` path exists but is not a git repository, the scripts fail and ask the user to repair or remove it manually instead of guessing.
- If a target path cannot be backed up or linked, the scripts stop with a concrete path-specific error.
- If Windows symbolic-link creation is unavailable, the PowerShell script must fall back to hard links for file targets on the same volume and directory junctions for directory targets such as `skills/superpowers` and downstream `skills` links; if the required Windows-native fallback also fails, the script stops with the underlying error.
- Allowed fallback:
  if a target already points to the correct source, the scripts leave it in place without backup or replacement.

## Acceptance
<!-- drift_anchor: acceptance -->

- Bash script verification covers:
  repository-local `skills/superpowers` link creation, failure on missing or invalid `superpowers` checkout, conflicting target backup, and idempotent rerun when links are already correct.
- PowerShell script verification covers the equivalent Windows hidden-directory cases plus successful `superpowers` junction creation and downstream file-target sync semantics when hard-link fallback is used.
- Error-path verification covers:
  missing or non-git `superpowers` paths and path-specific link failures.
- Repository docs are updated so a user can discover the recursive-clone submodule flow, the hidden-directory target layout, and the Windows PowerShell entrypoint without reading the script source.

## Deferred Decisions

- Whether the sync scripts should keep compatibility shims for legacy `--update-superpowers` usage or remove that mode entirely.
- Whether other downstream clients beyond the currently managed set should gain a `superpowers` namespace entry in this same change or a later follow-up.
