# Progress

## 2026-06-08

- Reframed the user-level collaboration model around `AGENTS.md`, `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, and `docs/superpowers/templates/`.
- Completed the light-init rewrite captured in:
  `docs/superpowers/specs/2026-06-08-user-level-light-init-spec.md`
  `docs/superpowers/plans/2026-06-08-user-level-light-init-implementation.md`
- Removed `.harness`, `AGENT_INDEX.md`, `PROJECT_LOGS.md`, and manifest-based truth from user-level bootstrap expectations while preserving Superpowers templates and the pointer-only `NEXT_STEP.md` rule.
- Verified the new contract by clearing old bootstrap references with `rg` and running `bash harness-bootstrap/scripts/validate_bootstrap.sh /Users/cory/.coding-cli`.
- Started the follow-up sync-agent-links rewrite for curated top-level `superpowers` skill exports and direct Codex skill links in:
  `docs/superpowers/specs/2026-06-08-sync-selected-superpowers-links-spec.md`
  `docs/superpowers/plans/2026-06-08-sync-selected-superpowers-links-implementation.md`
- Bash verification for the curated sync model now passes via `bash tests/sync-agent-links/test-sync-agent-links.sh`.
- PowerShell verification is still a local environment gap because `pwsh` is not installed in this macOS workspace.
- Added the Humanize RLCR sync loop captured in:
  `docs/superpowers/specs/2026-06-08-humanize-rlcr-sync-spec.md`
  `docs/superpowers/plans/2026-06-08-humanize-rlcr-sync-implementation.md`
- `sync-agent-links.sh` now manages a root-level ignored `humanize/` checkout and invokes `humanize/scripts/install-skill.sh --target codex` so Codex RLCR skills/runtime/hooks are installed during environment sync.
- `sync-agent-links.ps1` mirrors the Humanize checkout/install path and explicitly requires `bash` for the Humanize installer unless `HUMANIZE_SYNC=0`.
- Verified Humanize sync behavior with `bash tests/sync-agent-links/test-sync-agent-links.sh` and `./sync-agent-links.sh --dry-run`; `pwsh` remains unavailable locally, so PowerShell execution is still a verification gap.

## 2026-06-15

- Adapted `skills/grill-with-docs/SKILL.md` from a DDD glossary/ADR grilling workflow into a Superpowers spec-hardening workflow aligned with `NEXT_STEP.md`, `MEMORY.md`, active specs, active plans, and the lightweight project document spine.
- Preserved `CONTEXT-FORMAT.md` and `ADR-FORMAT.md` as optional compatibility references, but changed the default flow so `CONTEXT.md` and ADRs are not created unless the project already uses them or the user explicitly asks.
- Verified the skill structure with `python3 /Users/cory/.codex/skills/.system/skill-creator/scripts/quick_validate.py /Users/cory/.coding-cli/skills/grill-with-docs`.

## 2026-06-18

- Re-verified Humanize RLCR sync against the current `PolyArch/humanize` README and Codex install guide; the repo-owned Codex path remains `scripts/install-skill.sh --target codex`.
- Added a narrow sync-time repair for Humanize's current `install-codex-hooks.sh` `codex features list | grep -qE ...` probe so `pipefail` does not misreport supported `codex_hooks` builds.
- Mirrored the repair in `sync-agent-links.ps1`; local PowerShell execution remains a verification gap because `pwsh` is not installed here.
- Verified with `bash tests/sync-agent-links/test-sync-agent-links.sh` and a real `./sync-agent-links.sh` run.
- Confirmed Codex install results: `humanize`, `humanize-gen-plan`, `humanize-refine-plan`, and `humanize-rlcr` exist under `~/.codex/skills`; the Humanize runtime bundle exists; `~/.codex/hooks.json` contains `loop-codex-stop-hook.sh`; `.codex/config.toml` has `codex_hooks = true`.

## 2026-06-19

- Changed Codex config sync so `~/.codex/config.toml` is no longer linked by default. The sync scripts keep existing regular config files, convert legacy config symlinks to regular files, and only copy `.codex/config.toml` when explicitly requested with `--sync-codex-config` or `-SyncCodexConfig`.
- Removed device-specific `[projects."..."]` trust entries from the repo-level `.codex/config.toml` while preserving the current user-level config shape.

## 2026-06-24

- Added `skills/superman` as the user-level macro router for code work: lightweight path, Superpowers design/planning, Humanize RLCR execution, and doc-health routing.
- Updated `AGENTS.md` and `MEMORY.md` so the default flow is Superman routing, Superpowers brainstorm/write-plans, and Humanize execution evidence.
- Removed `skills/harness-lint-test-design` and `skills/harness-refactor` from the shared skills library.
- Updated `sync-agent-links.sh` and `sync-agent-links.ps1` so deprecated Codex skill links for those two removed skills are backed up/cleared on sync.
- Verified with `bash tests/sync-agent-links/test-sync-agent-links.sh`, `./sync-agent-links.sh --dry-run`, and `quick_validate.py` for `skills/superman` using `/Users/cory/anaconda3/bin/python` because the system Python lacks `PyYAML`; PowerShell execution remains a local gap because `pwsh` is unavailable.
- Slimmed `harness:init` bootstrap output to root collaboration docs, `docs/project/README.md`, and `docs/superpowers/templates/`, removing skeleton hooks, `.gitignore`, preset TOML machinery, `.harness`, `artifacts`, and default architecture/testing docs.
- Fixed migration bootstrap path handling so the skeleton root itself is skipped instead of being copied as an absolute-path-derived `Users/...` tree.
- Verified with greenfield and migration smoke bootstraps in temporary directories plus `bash harness-bootstrap/scripts/validate_bootstrap.sh` for each generated target and for `/Users/cory/.coding-cli`.

## 2026-06-25

- Added Kimi Code CLI support to the one-click sync scripts.
  - `sync-agent-links.sh` now links `AGENTS.md` to `$KIMI_CODE_HOME/AGENTS.md` (default `~/.kimi-code/AGENTS.md`) and the curated `skills/` directory to `$KIMI_CODE_HOME/skills`.
  - `sync-agent-links.ps1` mirrors the same Kimi links on Windows, using the existing file/directory symlink helpers with hard-link/junction fallbacks.
  - Both scripts honor the `KIMI_CODE_HOME` environment variable to override the default data root.
- Fixed Humanize RLCR sync so Kimi receives the same skills and runtime bundle as Codex.
  - `sync-agent-links.sh` and `sync-agent-links.ps1` now invoke `humanize/scripts/install-skill.sh --target both --kimi-skills-dir <shared>/skills --codex-skills-dir <shared>/skills` so the runtime is installed into the shared `skills/` directory that Kimi already symlinks.
  - `ensure_codex_skills_links` now runs after the Humanize install so `~/.codex/skills/humanize*` are symlinked to the shared runtime instead of being left as standalone copies.
- Added runtime patch for Codex CLI feature-name drift: current Codex CLI (`0.142.0`) exposes the native hooks feature as `hooks` instead of `codex_hooks`, and `codex features enable codex_hooks` only works because the CLI silently aliases it. The sync scripts now detect the available feature name and patch `humanize/scripts/install-codex-hooks.sh` to use `hooks` on newer CLI versions while keeping the `awk`-based probe that avoids `pipefail`/`SIGPIPE` false negatives.
- Verified with `bash tests/sync-agent-links/test-sync-agent-links.sh` (PASS). Updated the bash test fixture to support `--target both` and added assertions that Kimi sees `humanize/SKILL.md` and `humanize/hooks/loop-kimi-stop-hook.sh`. Updated the PowerShell test to create a fake Humanize remote and added a corresponding Kimi/Codex Humanize install assertion.
- Verified a real `./sync-agent-links.sh` run successfully installed Humanize for both targets and updated `~/.codex/hooks.json` to point at `/Users/cory/.coding-cli/skills/humanize/hooks/loop-codex-stop-hook.sh`.
- Confirmed the resulting layout:
  - `~/.kimi-code/skills/humanize` -> `/Users/cory/.coding-cli/skills/humanize` (via `~/.kimi-code/skills` -> `/Users/cory/.coding-cli/skills`)
  - `~/.codex/skills/humanize` -> `/Users/cory/.coding-cli/skills/humanize`
  - `~/.codex/hooks.json` contains the Humanize Stop hook command
- Added Kimi native Stop hook support so RLCR review gating can run from Kimi sessions.
  - `sync-agent-links.sh` and `sync-agent-links.ps1` now install a `loop-kimi-stop-hook.sh` wrapper into the shared Humanize runtime.
  - The wrapper consumes Kimi's stdin JSON event, delegates to `loop-codex-stop-hook.sh`, and translates the Claude-style `{"decision": "block", ...}` stdout protocol into Kimi's `exit 2` blocking semantics.
  - The sync scripts register the wrapper in `~/.kimi-code/config.toml` under `[[hooks]]` with `event = "Stop"` and `timeout = 600`.
  - Verified the wrapper blocks when Humanize loop preconditions are missing and allows exit once all loop state, summary, review, finalize, and methodology-analysis checks pass.
- Ran an end-to-end smoke test in `/tmp/kimi-rlcr-e2e-test`:
  - Started an RLCR loop with `setup-rlcr-loop.sh`
  - Completed round 0 (contract, implementation, summary, goal tracker)
  - Triggered the Kimi Stop hook wrapper manually with a Kimi-style JSON event on stdin
  - Observed the wrapper drive `codex exec` summary review, `codex review` code review, finalize phase, and methodology analysis
  - Final hook invocation returned `exit 0`, confirming the bridge works
- Re-runs of `./sync-agent-links.sh` still hit intermittent GitHub timeouts (`fatal: unable to access 'https://github.com/...': Recv failure: Operation timed out`). This is a network/GitHub reachability issue, not a yolo sandbox issue; the repos are already present locally so the install/link phases work once the initial `git pull` succeeds.
- PowerShell execution remains a local verification gap because `pwsh` is not installed on this macOS workspace.

## 2026-06-26

- Confirmed that Humanize skills under `skills/` are already generated by `sync-agent-links` calling `humanize/scripts/install-skill.sh --target both`; the only "self-maintained" residue was three tracked `SKILL.md` files for `humanize-gen-plan`, `humanize-refine-plan`, and `humanize-rlcr`.
- Updated `.gitignore` to explicitly ignore the managed `humanize/` checkout and all generated `skills/humanize*` artifacts, replacing the ambiguous `humanize` pattern.
- Removed the three tracked Humanize skill files from the git index with `git rm --cached` so they are treated as generated artifacts rather than maintained source files.
- Updated `tests/sync-agent-links/test-sync-agent-links.sh` to assert that both `/humanize/` and `/skills/humanize*` are gitignored, and to verify all four generated Humanize skill directories (`humanize`, `humanize-gen-plan`, `humanize-refine-plan`, `humanize-rlcr`) via `git check-ignore`.
- Verified with `bash tests/sync-agent-links/test-sync-agent-links.sh` (PASS).
- Updated `MEMORY.md` to state explicitly that `skills/humanize*` are generated artifacts recreated on every sync and must not be maintained by hand.
