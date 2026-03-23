# Next Step

Run the remaining Bash-side verification flow and record:

- whether `bash tests/sync-agent-links/test-sync-agent-links.sh` passes in an environment where `bash` can launch without `Bash/Service/CreateInstance/E_ACCESSDENIED`
- whether the Bash behavior matches the already-passing PowerShell submodule-only flow
- whether the simplified flow still matches the Windows file-link fallback evidence in `artifacts/sync-agent-links/2026-03-23-windows-prompt-skill-sync.md`
