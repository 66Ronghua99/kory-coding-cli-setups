# Current State

## Code-Backed Baseline

- The repository now has two sync entrypoints:
  - [`sync-agent-links.sh`](/Users/cory/.coding-cli/sync-agent-links.sh) for macOS/Linux shells
  - [`sync-agent-links.ps1`](/Users/cory/.coding-cli/sync-agent-links.ps1) for Windows PowerShell
- [`superpowers`](/Users/cory/.coding-cli/superpowers) is tracked as a Git submodule and is expected to be initialized through `git clone --recurse-submodules` or `git submodule update --init --recursive`.
- The sync scripts repair or recreate [`skills/superpowers`](/Users/cory/.coding-cli/skills/superpowers) as a local generated link to [`superpowers/skills`](/Users/cory/.coding-cli/superpowers/skills); that generated link is ignored by Git instead of being tracked.
- The Bash implementation keeps the existing downstream target layout:
  - `.claude/CLAUDE.md`, `.claude/skills`, `.claude/settings.json`, `.claude/statusline-command.sh`
  - `.gemini/GEMINI.md`, `.gemini/skills`
  - `.copilot/copilot-instructions.md`, `.copilot/skills`, `.copilot/AGENTS.md`
  - `.codex/AGENTS.md`, `.codex/config.toml`, `.codex/agents`, `.codex/skills/skills`
- The PowerShell implementation mirrors the same hidden-directory mapping except for `statusline-command.sh`, which remains Bash-only by user choice.
- On Windows, the PowerShell sync now falls back to hard links for file targets when file symlink privilege is unavailable, while directory targets still fall back to junctions.
- Fresh Windows prompt/skill sync evidence is recorded in [`artifacts/sync-agent-links/2026-03-23-windows-prompt-skill-sync.md`](/Users/cory/.coding-cli/artifacts/sync-agent-links/2026-03-23-windows-prompt-skill-sync.md).
- Regression coverage currently lives in [`tests/sync-agent-links/test-sync-agent-links.sh`](/Users/cory/.coding-cli/tests/sync-agent-links/test-sync-agent-links.sh) and [`tests/sync-agent-links/test-sync-agent-links.ps1`](/Users/cory/.coding-cli/tests/sync-agent-links/test-sync-agent-links.ps1). The PowerShell harness now checks downstream prompt files for live-link behavior too, but the full clone/update fixture-remote path is still blocked in this environment by a Git for Windows `sh.exe` signal-pipe failure.

## Follow-Up

- Decide whether the sync scripts should keep their legacy clone/update code paths now that `superpowers` is a formal submodule rather than a loose nested checkout.
- If Windows-specific path quirks appear in Codex/Claude app builds, fold those observed paths back into the sync docs before expanding scope further.
