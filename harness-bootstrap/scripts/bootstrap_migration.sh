#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$(pwd)}"
PACK_ROOT="${2:-$(cd "$(dirname "$0")/.." && pwd)}"
SKELETON_DIR="$PACK_ROOT/skeleton"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Target directory does not exist: $TARGET_DIR" >&2
  exit 1
fi

while IFS= read -r -d '' path; do
  rel_path="${path#$SKELETON_DIR/}"
  dest_path="$TARGET_DIR/$rel_path"

  if [[ -d "$path" ]]; then
    mkdir -p "$dest_path"
    continue
  fi

  if [[ ! -e "$dest_path" ]]; then
    mkdir -p "$(dirname "$dest_path")"
    cp "$path" "$dest_path"
  fi
done < <(find "$SKELETON_DIR" \( -type d -o -type f \) -print0)

if [[ -f "$TARGET_DIR/.harness/bootstrap.toml.example" && ! -f "$TARGET_DIR/.harness/bootstrap.toml" ]]; then
  cp "$TARGET_DIR/.harness/bootstrap.toml.example" "$TARGET_DIR/.harness/bootstrap.toml"
fi

if [[ -f "$TARGET_DIR/.harness/bootstrap.toml" ]]; then
  tmp_file="$(mktemp)"
  sed \
    -e 's/^mode = .*/mode = "migration"/' \
    -e 's/^preset = .*/preset = "none"/' \
    "$TARGET_DIR/.harness/bootstrap.toml" > "$tmp_file"
  mv "$tmp_file" "$TARGET_DIR/.harness/bootstrap.toml"
fi

state_file="$TARGET_DIR/docs/project/current-state.md"
if [[ ! -f "$state_file" ]]; then
  {
    echo "# Current State"
    echo
    echo "## Detected Markers"
    for marker in .git package.json pyproject.toml go.mod Cargo.toml src app lib; do
      if [[ -e "$TARGET_DIR/$marker" ]]; then
        echo "- $marker"
      fi
    done
    echo
    echo "## Follow-Up"
    echo "- Review repository topology and update architecture/testing docs where skeleton defaults are too generic"
    echo "- Use Superpowers to write the first approved migration spec before code changes"
  } > "$state_file"
fi

echo "migration-bootstrap-complete"
