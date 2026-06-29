#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$(pwd)}"
PACK_ROOT="${2:-$(cd "$(dirname "$0")/.." && pwd)}"
SKELETON_DIR="$PACK_ROOT/skeleton"
GITIGNORE_SCRIPT="$PACK_ROOT/scripts/ensure_harness_gitignore.sh"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Target directory does not exist: $TARGET_DIR" >&2
  exit 1
fi

while IFS= read -r -d '' path; do
  if [[ "$path" == "$SKELETON_DIR" ]]; then
    continue
  fi

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

bash "$GITIGNORE_SCRIPT" "$TARGET_DIR"

echo "migration-bootstrap-complete"
