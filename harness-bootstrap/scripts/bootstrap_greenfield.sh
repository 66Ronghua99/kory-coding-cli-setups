#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$(pwd)}"
PACK_ROOT="${2:-$(cd "$(dirname "$0")/.." && pwd)}"
SKELETON_DIR="$PACK_ROOT/skeleton"
MODE_SCRIPT="$PACK_ROOT/scripts/detect_project_mode.sh"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Target directory does not exist: $TARGET_DIR" >&2
  exit 1
fi

MODE="$($MODE_SCRIPT "$TARGET_DIR")"
if [[ "$MODE" != "greenfield" ]]; then
  echo "Refusing greenfield bootstrap for non-greenfield directory: $TARGET_DIR" >&2
  exit 1
fi

cp -R "$SKELETON_DIR"/. "$TARGET_DIR"/

if [[ -f "$TARGET_DIR/.harness/bootstrap.toml.example" && ! -f "$TARGET_DIR/.harness/bootstrap.toml" ]]; then
  cp "$TARGET_DIR/.harness/bootstrap.toml.example" "$TARGET_DIR/.harness/bootstrap.toml"
fi

if [[ -f "$TARGET_DIR/.harness/bootstrap.toml" ]]; then
  tmp_file="$(mktemp)"
  sed \
    -e 's/^mode = .*/mode = "greenfield"/' \
    -e 's/^preset = .*/preset = "none"/' \
    "$TARGET_DIR/.harness/bootstrap.toml" > "$tmp_file"
  mv "$tmp_file" "$TARGET_DIR/.harness/bootstrap.toml"
fi

echo "greenfield-bootstrap-complete"
