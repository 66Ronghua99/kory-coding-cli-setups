---
doc_type: spec
status: approved
supersedes: []
related:
  - docs/superpowers/specs/2026-06-08-sync-selected-superpowers-links-spec.md
---

# Humanize RLCR Sync Spec

## Problem

Humanize RLCR can provide a Codex Stop-hook execution gate for plans created by Superpowers, but its Codex runtime currently has to be installed manually on each machine. That manual step is easy to forget when setting up a new environment, and it leaves the user's Codex configuration without the expected RLCR skills, runtime bundle, and native Stop hook.

## Success

- Running `sync-agent-links.sh` ensures a local `humanize` checkout exists and is fast-forward updated.
- The sync flow invokes Humanize's own Codex installer so `humanize-rlcr` and its runtime are installed into the active Codex home.
- The sync flow enables/maintains the native Humanize Codex Stop hook through the Humanize installer rather than reimplementing hook JSON merging.
- The planning flow remains Superpowers-first. Humanize plan-generation skills may be installed as runtime companions, but they are not treated as the user's primary planning workflow.
- Humanize sync can be disabled with an environment flag for machines that should not install RLCR.

## Out Of Scope

- Replacing Superpowers specs or plans with Humanize `gen-plan`.
- Manually copying only one Humanize skill without the runtime bundle and Stop hook.
- Reimplementing Humanize installer internals in this repository.

## Frozen Contracts
<!-- drift_anchor: frozen_contracts -->

- `humanize` lives at the repository root as `humanize/` by default.
- Sync owns the `humanize` checkout lifecycle: clone when missing and pull with fast-forward-only behavior when present.
- Default Humanize remote is `https://github.com/PolyArch/humanize.git`.
- Default Humanize branch is `main`.
- `HUMANIZE_DIR`, `HUMANIZE_REMOTE_URL`, and `HUMANIZE_BRANCH` override those defaults.
- `HUMANIZE_SYNC=0` disables Humanize sync and install.
- Bash sync invokes `humanize/scripts/install-skill.sh --target codex` after ensuring the checkout.
- PowerShell sync mirrors the same lifecycle and invokes the same installer when available in the platform environment.
- Humanize RLCR is an execution gate for Superpowers plan files such as `docs/superpowers/plans/<plan>.md`.
- The generated local `humanize/` checkout is ignored by git.

## Acceptance
<!-- drift_anchor: acceptance -->

- Bash regression coverage proves fresh Humanize clone, installer invocation, opt-out behavior, dry-run behavior, git-ignore coverage, and idempotent reruns.
- Existing Superpowers sync behavior continues to pass.
- PowerShell script is updated to mirror the Bash behavior; if local `pwsh` is unavailable, that remains an explicit verification gap rather than an untested success claim.
