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
- The sync model has since been simplified further: `superpowers` is expected to arrive through Git submodule init/update, and the sync scripts now only validate the local checkout plus regenerate the `skills/superpowers` link.
- Re-ran the simplified PowerShell regression harness after the submodule-only refactor and it passed in this Windows session.
- The matching Bash regression harness could not be executed in this environment because launching `bash` fails immediately with `Bash/Service/CreateInstance/E_ACCESSDENIED`.
