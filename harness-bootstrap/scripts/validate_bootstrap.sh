#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$(pwd)}"

required_paths=(
  "AGENTS.md"
  "AGENT_INDEX.md"
  "PROGRESS.md"
  "MEMORY.md"
  "NEXT_STEP.md"
  ".harness/bootstrap.toml"
  "docs/project/README.md"
  "docs/architecture/overview.md"
  "docs/architecture/layers.md"
  "docs/testing/strategy.md"
  "docs/superpowers/templates/SPEC_TEMPLATE.md"
  "docs/superpowers/templates/PLAN_TEMPLATE.md"
  "docs/superpowers/templates/CHANGE_REQUEST_TEMPLATE.md"
  "docs/superpowers/templates/EVIDENCE_TEMPLATE.md"
)

missing=0

for rel_path in "${required_paths[@]}"; do
  if [[ ! -e "$TARGET_DIR/$rel_path" ]]; then
    echo "missing: $rel_path" >&2
    missing=1
  fi
done

required_manifest_keys=(
  'bootstrap_version = '
  'mode = '
  'preset = '
  'entry_skill = '
  'governance_model = '
  'templates_dir = '
  'doc_health_skill = '
  'lint_test_skill = '
)

manifest_path="$TARGET_DIR/.harness/bootstrap.toml"
if [[ -f "$manifest_path" ]]; then
  for key in "${required_manifest_keys[@]}"; do
    if ! grep -F "$key" "$manifest_path" >/dev/null 2>&1; then
      echo "manifest-key-missing: $key" >&2
      missing=1
    fi
  done
fi

no_absolute_path_files=(
  "AGENTS.md"
  "AGENT_INDEX.md"
  "NEXT_STEP.md"
  ".harness/bootstrap.toml"
)

for rel_path in "${no_absolute_path_files[@]}"; do
  file_path="$TARGET_DIR/$rel_path"
  if [[ ! -f "$file_path" ]]; then
    continue
  fi

  if command -v rg >/dev/null 2>&1; then
    if rg -n '/Users/' "$file_path" >/dev/null 2>&1; then
      echo "absolute-path: $rel_path contains '/Users/'" >&2
      missing=1
    fi
  else
    if grep -n '/Users/' "$file_path" >/dev/null 2>&1; then
      echo "absolute-path: $rel_path contains '/Users/'" >&2
      missing=1
    fi
  fi
done

if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

echo "bootstrap-valid"
