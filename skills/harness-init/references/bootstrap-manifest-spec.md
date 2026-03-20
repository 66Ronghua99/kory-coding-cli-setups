# Bootstrap Manifest Spec

Use `.harness/bootstrap.toml` as the repository-local summary of how Harness is initialized.

## Required Keys

- `bootstrap_version`
- `mode`
- `preset`
- `entry_skill`
- `governance_model`
- `templates_dir`
- `doc_health_skill`
- `lint_test_skill`

## Rules

- The manifest describes governance structure, not executable commands.
- Values must stay repository-relative or symbolic; do not write machine-specific absolute paths.
- `mode` is determined by bootstrap detection, never by chat guesswork.
- If the repository later adds runtime automation, that belongs to a future runtime-specific skill, not to this manifest version.
