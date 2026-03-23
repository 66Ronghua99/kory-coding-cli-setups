# Current State

## Code-Backed Baseline

- The repository now has two sync entrypoints:
  - [`sync-agent-links.sh`](/Users/cory/.coding-cli/sync-agent-links.sh) for macOS/Linux shells
  - [`sync-agent-links.ps1`](/Users/cory/.coding-cli/sync-agent-links.ps1) for Windows PowerShell
- Both sync scripts treat [`superpowers`](/Users/cory/.coding-cli/superpowers) as a managed checkout:
  - clone it when missing
  - optionally update it through explicit update mode
  - repair [`skills/superpowers`](/Users/cory/.coding-cli/skills/superpowers) so the existing whole-directory `skills` sync keeps exposing Superpowers downstream
- The Bash implementation keeps the existing downstream target layout:
  - `.claude/CLAUDE.md`, `.claude/skills`, `.claude/settings.json`, `.claude/statusline-command.sh`
  - `.gemini/GEMINI.md`, `.gemini/skills`
  - `.copilot/copilot-instructions.md`, `.copilot/skills`, `.copilot/AGENTS.md`
  - `.codex/AGENTS.md`, `.codex/config.toml`, `.codex/agents`, `.codex/skills/skills`
- The PowerShell implementation mirrors the same hidden-directory mapping except for `statusline-command.sh`, which remains Bash-only by user choice.
- Regression coverage currently lives in [`tests/sync-agent-links/test-sync-agent-links.sh`](/Users/cory/.coding-cli/tests/sync-agent-links/test-sync-agent-links.sh). A companion PowerShell check script exists at [`tests/sync-agent-links/test-sync-agent-links.ps1`](/Users/cory/.coding-cli/tests/sync-agent-links/test-sync-agent-links.ps1), but it has not been executed in this macOS session because `pwsh` is unavailable here.

## Follow-Up

- Run the new PowerShell sync flow on a real Windows machine and capture the first junction/symlink verification evidence.
- If Windows-specific path quirks appear in Codex/Claude app builds, fold those observed paths back into the sync docs before expanding scope further.
