# Next Step

Decide whether to simplify the sync scripts around the new submodule-first `superpowers` model, then record:

- whether clone/update flags should be removed in favor of `git submodule update --init --recursive`
- whether the remaining tests should stop using fixture remotes and instead assume an initialized local submodule
- whether the simplified flow still matches the Windows file-link fallback evidence in `artifacts/sync-agent-links/2026-03-23-windows-prompt-skill-sync.md`
