---
doc_type: spec
status: approved
supersedes: []
related:
  - docs/superpowers/specs/2026-03-23-cross-platform-sync-and-superpowers-bootstrap-design.md
---

# Sync Selected Superpowers Links Spec

## Problem

The current sync flow exposes `superpowers` through `skills/superpowers -> superpowers/skills`, which adds an extra namespace layer that some clients do not discover correctly. The Codex target also nests the skills directory one level too deep at `.codex/skills/skills`. At the same time, the current sync scripts require a pre-initialized `superpowers` checkout instead of handling clone/pull automatically.

## Success

- Running `sync-agent-links.sh` or `sync-agent-links.ps1` ensures the local `superpowers` checkout exists and is updated with fast-forward-only semantics.
- The repository-local `skills/` directory exposes a small curated set of top-level links directly to selected `superpowers` skills instead of a `skills/superpowers` subtree.
- Downstream clients discover those curated skills without an extra path layer, including Codex.
- Generated top-level `skills/<skill-name>` links remain local sync artifacts and are not tracked by git.

## Out Of Scope

- Exposing every skill from `superpowers/skills`.
- Replacing the current shell-native sync implementation with another runtime.

## Critical Paths

1. Fresh repo sync: clone `superpowers` when missing, create curated top-level skill links under `skills/`, then sync client homes.
2. Existing repo sync: fast-forward update the local `superpowers` checkout, repair curated links if needed, then sync client homes idempotently.

## Frozen Contracts
<!-- drift_anchor: frozen_contracts -->

- `superpowers` lives at the repository root as `superpowers/`.
- Sync owns `superpowers` lifecycle: clone when missing, pull with fast-forward-only behavior when present.
- The curated export set is:
  `using-superpowers`, `brainstorming`, `writing-plans`, `executing-plans`, `test-driven-development`, and `verification-before-completion`.
- Each curated skill is exposed as a top-level generated link under `skills/<name> -> ../superpowers/skills/<name>` or the platform-equivalent target.
- `skills/superpowers` is no longer the exposure model and should be removed if present.
- Codex receives the repository `skills/` tree at `.codex/skills`, not `.codex/skills/skills`.
- Curated top-level skill links are generated local artifacts and must not be committed.

## Architecture Invariants

- Repository-local first-party skills and curated `superpowers` links coexist in the same `skills/` directory without nested namespaces.
- Sync should only manage the curated set, leaving unrelated local skills untouched.
- Git ignore rules should prevent generated curated links from polluting repository status.

## Failure Policy

- If `superpowers` clone or pull fails, sync stops with an actionable error.
- If `superpowers` exists but is not a git repository, sync fails instead of guessing how to repair it.
- If a curated target path already exists with conflicting content, sync backs it up before replacement.
- Allowed fallback:
  if a curated link or downstream client target already points to the correct source, sync leaves it untouched.

## Acceptance
<!-- drift_anchor: acceptance -->

- Bash regression coverage proves fresh clone, fast-forward update, curated top-level link creation, removal of the old `skills/superpowers` model, Codex direct `.codex/skills` mapping, and idempotent reruns.
- PowerShell regression coverage proves the same high-level contract for Windows hidden-directory targets.
- Repository ignore rules prevent curated generated links from showing up as tracked changes.

## Deferred Decisions

- Whether the curated export set should later grow to include additional frequently used `superpowers` skills.
