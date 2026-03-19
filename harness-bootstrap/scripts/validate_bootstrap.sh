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

if [[ "$missing" -ne 0 ]]; then
  exit 1
fi

echo "bootstrap-valid"
