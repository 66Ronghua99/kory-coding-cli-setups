# Memory

## Stable Notes

- This repository was initialized from the local Harness bootstrap pack.
- User-level bootstrap is intentionally lightweight: required collaboration files are `AGENTS.md`, `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, plus `docs/project/README.md` and `docs/superpowers/templates/`.
- `harness:init` bootstrap must not create local hooks, `.gitignore`, preset/manifest TOML files, `.harness`, `artifacts`, or default `docs/architecture` and `docs/testing` trees.
- Template files under `docs/superpowers/templates/` define the required document shape.
- `superman` is the user-level macro router for code work: it decides whether to take a lightweight path, use Superpowers for design/planning, use Humanize RLCR for execution, or run doc-health.
- `harness:doc-health` owns repository truth and pointer consistency.
- `harness:lint-test-design` and `harness:refactor` were removed from the shared skills library; use normal tests, review, and concrete follow-up tasks instead of routing to those skills.
- `NEXT_STEP.md` is a pointer-only file; if no follow-up task exists after completion, it should be cleared instead of carrying stale prose.
- `PROGRESS.md` is an accumulating execution summary, not a mandatory read on every coding turn.
- The shared `skills` directory remains the downstream sync unit for agent homes; `superpowers` is exposed through a curated generated set of top-level links under [`skills/`](/Users/cory/.coding-cli/skills), not through a nested `skills/superpowers` namespace.
- `superpowers` sync is owned by [`sync-agent-links.sh`](/Users/cory/.coding-cli/sync-agent-links.sh) and [`sync-agent-links.ps1`](/Users/cory/.coding-cli/sync-agent-links.ps1): they clone or fast-forward the checkout and regenerate the curated top-level links as local, ignored artifacts.
- `sync-agent-links.sh` is the macOS/Linux source of truth for the target mapping, and [`sync-agent-links.ps1`](/Users/cory/.coding-cli/sync-agent-links.ps1) mirrors that behavior for Windows hidden directories under `%USERPROFILE%`.
- Humanize RLCR sync is owned by [`sync-agent-links.sh`](/Users/cory/.coding-cli/sync-agent-links.sh) and mirrored in [`sync-agent-links.ps1`](/Users/cory/.coding-cli/sync-agent-links.ps1): by default they manage a root-level ignored `humanize/` checkout from `https://github.com/PolyArch/humanize.git`, fast-forward it, and invoke `humanize/scripts/install-skill.sh --target both` with a shared `skills/` directory so both Kimi and Codex see the Humanize runtime, skills, and hooks. The resulting `skills/humanize*` directories are generated artifacts and must not be maintained by hand; they are recreated on every sync.
- Codex CLI feature naming has drifted: recent versions (e.g., `0.142.0`) expose native hooks as the `hooks` feature while still accepting `codex_hooks` as an alias for `codex features enable`. The sync scripts detect the available feature name at runtime and patch `humanize/scripts/install-codex-hooks.sh` accordingly; they also keep the `awk`-based probe to avoid `pipefail`/`SIGPIPE` false negatives caused by `grep -q` closing the pipe early.
- Kimi Code CLI also supports native hooks via `[[hooks]]` entries in `~/.kimi-code/config.toml`. The sync scripts register a Kimi Stop hook that wraps Humanize's `loop-codex-stop-hook.sh`: it reads Kimi's stdin JSON event, delegates to the Codex/Claude stop hook, and translates the stdout `{"decision": "block"}` protocol into Kimi's expected `exit 2` block semantics. This lets Kimi sessions drive the same RLCR review gating as Codex sessions.
- Humanize remains the execution gate for large-feature implementation in this user-level workflow. Superpowers specs and plans remain the planning source of truth; Humanize `gen-plan` and `refine-plan` are not the primary planning path.
- Humanize sync can be disabled with `HUMANIZE_SYNC=0`, and `HUMANIZE_DIR`, `HUMANIZE_REMOTE_URL`, and `HUMANIZE_BRANCH` override the managed checkout location/source.
- Codex `config.toml` is intentionally not linked. `sync-agent-links` keeps an existing regular `~/.codex/config.toml` by default, converts legacy config symlinks into regular files, and only copies the repo config when `--sync-codex-config` / `-SyncCodexConfig` is passed explicitly.
- On Windows, `sync-agent-links.ps1` falls back to hard links for file targets like `CLAUDE.md` and `AGENTS.md` when symbolic-link privilege is unavailable; directory targets still fall back to junctions.
- Windows backup paths must be normalized under `.coding-cli-sync-backups/<timestamp>/<drive>/...`; appending raw absolute paths creates invalid or misleading backup destinations.
- `grill-with-docs` is adapted for this workflow as a Superpowers spec-hardening skill. Its default output is inline spec improvement plus necessary `NEXT_STEP.md`/plan synchronization, not automatic `CONTEXT.md` or ADR creation.

## Working Heuristics

- Keep repository-local docs ahead of implementation drift.
- Encode repeated review feedback into templates, focused tests, documented follow-up tasks, or small cleanup plans.
- Prefer explicit failure semantics over silent fallback behavior.
- Route stale docs to `harness:doc-health`; do not route work to removed `harness:lint-test-design` or `harness:refactor` skills.
- When state is unclear, recover truth from `NEXT_STEP.md`, current spec/plan/checklist completion, and bounded code review before editing progress summaries.
- Treat missing `pwsh` on macOS as a verification gap to document, not a reason to claim Windows execution was tested.
- When PowerShell runs native tools like `git` or `cmd`, check exit codes explicitly; non-zero native exits do not automatically become terminating errors.
- Use `CONTEXT.md`/ADR capture from `grill-with-docs` only when a project already uses those files or the user explicitly asks for glossary/ADR maintenance.
