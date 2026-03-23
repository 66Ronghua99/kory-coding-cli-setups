---
date: 2026-03-23
platform: windows-powershell
scope: sync-agent-links.ps1 prompt-and-skill sync
---

# Evidence

- Ran a Windows PowerShell fixture sync with a pre-created local `superpowers` git checkout and verified:
  - conflicting `.claude/CLAUDE.md` was backed up under `.coding-cli-sync-backups/.../C/...`
  - `.claude/CLAUDE.md` synced successfully
  - `.codex/skills/skills/sample-skill/SKILL.md` synced successfully
  - `.codex/skills/skills/superpowers/using-superpowers/SKILL.md` synced successfully
  - editing the source `CLAUDE.md` after sync updated the downstream `.claude/CLAUDE.md`, confirming the Windows file-link fallback preserved live sync semantics
- Updated the PowerShell regression script to avoid the built-in `$HOME` variable collision and to assert that downstream prompt files still reflect source updates.
- Full `tests/sync-agent-links/test-sync-agent-links.ps1` clone/update coverage remains blocked in this environment because Git for Windows fails local fixture remote `push`/`clone` with `sh.exe: couldn't create signal pipe, Win32 error 5`.
