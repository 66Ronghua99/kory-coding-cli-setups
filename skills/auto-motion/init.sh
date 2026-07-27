#!/bin/bash
# auto-motion-init — inject auto-motion assets into a working directory
# Usage: auto-motion-init [target-directory]
# Default target: current directory

set -euo pipefail

TARGET="${1:-.}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUNDLE="$SCRIPT_DIR/bundle"

if [ ! -d "$BUNDLE" ]; then
  echo "ERROR: bundle directory not found at $BUNDLE" >&2
  echo "Make sure auto-motion is installed at ~/.omp/agent/skills/auto-motion/" >&2
  exit 1
fi

echo "=== auto-motion init ==="
echo "Target: $TARGET"
echo ""

mkdir -p "$TARGET"

# Skills → .omp/skills/
echo "Installing skills..."
mkdir -p "$TARGET/.omp/skills"
shopt -s dotglob nullglob
for skill in "$BUNDLE/skills/"*; do
  [ -d "$skill" ] || continue
  cp -r "$skill" "$TARGET/.omp/skills/"
  # Restore SKILL.md from .md.bundle (stripped to prevent OMP recursive discovery)
  find "$TARGET/.omp/skills/$(basename "$skill")" -name '*.md.bundle' | while read f; do
    mv "$f" "${f%.md.bundle}.md"
  done
done
echo "  $(ls "$TARGET/.omp/skills/" | tr '\n' ' ')"

# Agents → .omp/agents/
echo "Installing agents..."
mkdir -p "$TARGET/.omp/agents"
cp "$BUNDLE/agents/"*.md "$TARGET/.omp/agents/"
echo "  $(ls "$TARGET/.omp/agents/")"

# Config → .omp/
echo "Installing config..."
cp "$BUNDLE/config/config.yml" "$TARGET/.omp/config.yml" 2>/dev/null || true
mkdir -p "$TARGET/.omp/model-profiles" "$TARGET/.omp/auto-motion"
cp "$BUNDLE/config/model-profiles/"*.yml "$TARGET/.omp/model-profiles/" 2>/dev/null || true
cp "$BUNDLE/config/auto-motion/"*.yml "$TARGET/.omp/auto-motion/" 2>/dev/null || true

# Scripts → scripts/
echo "Installing scripts..."
mkdir -p "$TARGET/scripts/lib"
cp "$BUNDLE/scripts/"*.mjs "$TARGET/scripts/" 2>/dev/null || true
cp "$BUNDLE/scripts/lib/"*.mjs "$TARGET/scripts/lib/" 2>/dev/null || true

# Schemas → schemas/
echo "Installing schemas..."
mkdir -p "$TARGET/schemas"
cp "$BUNDLE/schemas/"*.json "$TARGET/schemas/"

# Templates → templates/
echo "Installing templates..."
mkdir -p "$TARGET/templates/scene"
cp -r "$BUNDLE/templates/scene/"* "$TARGET/templates/scene/"

# Root files
echo "Installing root files..."
for f in package.json package-lock.json .env.example .gitignore; do
  [ -f "$BUNDLE/$f" ] && cp "$BUNDLE/$f" "$TARGET/$f"
done
shopt -u dotglob nullglob

# Install dependencies
echo ""
echo "Installing npm dependencies..."
cd "$TARGET"
npm install --ignore-scripts 2>&1 | tail -1

echo ""
echo "=== auto-motion ready ==="
echo "Next: cd $(cd "$TARGET" && pwd) && omp"
echo "Then enter /skill:auto-motion"
