#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$(pwd)}"

required_paths=(
  "AGENTS.md"
  ".gitignore"
  "PROGRESS.md"
  "MEMORY.md"
  "NEXT_STEP.md"
  "docs/project/README.md"
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

required_gitignore_entries=(
  "docs/superpowers/"
  "/*.md"
  "!/AGENTS.md"
)

gitignore_path="$TARGET_DIR/.gitignore"
if [[ -f "$gitignore_path" ]]; then
  for entry in "${required_gitignore_entries[@]}"; do
    if ! grep -Fqx "$entry" "$gitignore_path"; then
      echo "gitignore-missing: $entry" >&2
      missing=1
    fi
  done

  if git -C "$TARGET_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if ! git -C "$TARGET_DIR" check-ignore --no-index -q "PROGRESS.md"; then
      echo "gitignore-not-ignored: PROGRESS.md" >&2
      missing=1
    fi

    if ! git -C "$TARGET_DIR" check-ignore --no-index -q "docs/superpowers/templates/SPEC_TEMPLATE.md"; then
      echo "gitignore-not-ignored: docs/superpowers/templates/SPEC_TEMPLATE.md" >&2
      missing=1
    fi

    if git -C "$TARGET_DIR" check-ignore --no-index -q "AGENTS.md"; then
      echo "gitignore-invalid: AGENTS.md must remain trackable" >&2
      missing=1
    fi
  fi
fi

no_absolute_path_files=(
  "AGENTS.md"
  "NEXT_STEP.md"
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
