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
- Both sync scripts now require an already initialized `superpowers` submodule and fail with an actionable submodule command instead of cloning or updating it themselves.
- On Windows, the PowerShell sync now falls back to hard links for file targets when file symlink privilege is unavailable, while directory targets still fall back to junctions.
- Fresh Windows prompt/skill sync evidence is recorded in [`artifacts/sync-agent-links/2026-03-23-windows-prompt-skill-sync.md`](/Users/cory/.coding-cli/artifacts/sync-agent-links/2026-03-23-windows-prompt-skill-sync.md).
- Regression coverage currently lives in [`tests/sync-agent-links/test-sync-agent-links.sh`](/Users/cory/.coding-cli/tests/sync-agent-links/test-sync-agent-links.sh) and [`tests/sync-agent-links/test-sync-agent-links.ps1`](/Users/cory/.coding-cli/tests/sync-agent-links/test-sync-agent-links.ps1). Those tests now assume an initialized local `superpowers` checkout rather than a fixture remote. The PowerShell test passes in this Windows session; the Bash test is still blocked here by `Bash/Service/CreateInstance/E_ACCESSDENIED`.

## Follow-Up

- Capture fresh Bash-side verification evidence for the simplified submodule-only sync flow in an environment where `bash` can launch.
- If Windows-specific path quirks appear in Codex/Claude app builds, fold those observed paths back into the sync docs before expanding scope further.
