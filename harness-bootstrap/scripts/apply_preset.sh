#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$(pwd)}"
PRESET_NAME="${2:-none}"
PACK_ROOT="${3:-$(cd "$(dirname "$0")/.." && pwd)}"
PRESET_DIR="$PACK_ROOT/presets/$PRESET_NAME"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Target directory does not exist: $TARGET_DIR" >&2
  exit 1
fi

if [[ "$PRESET_NAME" == "none" ]]; then
  echo "preset-none"
  exit 0
fi

if [[ ! -d "$PRESET_DIR" ]]; then
  echo "Unknown preset: $PRESET_NAME" >&2
  exit 1
fi

echo "Preset '$PRESET_NAME' is not implemented yet." >&2
exit 1
