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

echo "greenfield-bootstrap-complete"
