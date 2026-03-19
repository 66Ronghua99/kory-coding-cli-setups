#!/usr/bin/env bash
set -euo pipefail

TARGET_DIR="${1:-$(pwd)}"

if [[ ! -d "$TARGET_DIR" ]]; then
  echo "Target directory does not exist: $TARGET_DIR" >&2
  exit 1
fi

markers=(
  ".git"
  "package.json"
  "pyproject.toml"
  "go.mod"
  "Cargo.toml"
  "src"
  "app"
  "lib"
)

for marker in "${markers[@]}"; do
  if [[ -e "$TARGET_DIR/$marker" ]]; then
    echo "migration"
    exit 0
  fi
done

shopt -s nullglob dotglob
entries=("$TARGET_DIR"/*)
non_ignorable=()

for path in "${entries[@]}"; do
  base="$(basename "$path")"
  case "$base" in
    ".DS_Store"|".gitignore"|".gitattributes"|".editorconfig"|"README.md"|"LICENSE"|"LICENSE.md"|".env.example")
      ;;
    *)
      non_ignorable+=("$base")
      ;;
  esac
done

if [[ ${#non_ignorable[@]} -eq 0 ]]; then
  echo "greenfield"
else
  echo "migration"
fi
