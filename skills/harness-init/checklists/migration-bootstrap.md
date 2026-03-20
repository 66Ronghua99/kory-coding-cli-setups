# Migration Bootstrap Checklist

- Confirm the repository already contains product markers.
- Add missing governance files without overwriting product code.
- Materialize `.harness/bootstrap.toml` if absent.
- Write `docs/project/current-state.md` if absent.
- Preserve existing repository behavior; bootstrap only the governance layer.
- Do not vendor non-init Harness tools into the repository.
