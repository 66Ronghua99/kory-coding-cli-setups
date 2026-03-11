#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_ROOT="${HOME}/.coding-cli-sync-backups/$(date +%Y%m%d_%H%M%S)"
DRY_RUN=0

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
fi

log() {
  printf '%s\n' "$*"
}

run_cmd() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    eval "$@"
  fi
}

ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    run_cmd "mkdir -p \"$dir\""
  fi
}

backup_path() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    ensure_dir "$BACKUP_ROOT"
    local rel="${target#/}"
    local backup_target="$BACKUP_ROOT/$rel"
    ensure_dir "$(dirname "$backup_target")"
    run_cmd "mv \"$target\" \"$backup_target\""
    log "Backed up $target -> $backup_target"
  fi
}

ensure_symlink() {
  local source="$1"
  local target="$2"

  ensure_dir "$(dirname "$target")"

  if [[ -L "$target" ]]; then
    local current
    current="$(readlink "$target")"
    if [[ "$current" == "$source" ]]; then
      log "OK symlink: $target -> $source"
      return
    fi
  fi

  if [[ -e "$target" || -L "$target" ]]; then
    backup_path "$target"
  fi

  run_cmd "ln -s \"$source\" \"$target\""
  log "Linked $target -> $source"
}

cleanup_codex_skill_overrides() {
  local codex_skills_dir="${HOME}/.codex/skills"
  [[ -d "$codex_skills_dir" ]] || return

  for path in "$codex_skills_dir"/*; do
    [[ -e "$path" || -L "$path" ]] || continue
    local name
    name="$(basename "$path")"
    if [[ "$name" == ".system" || "$name" == "skills" ]]; then
      continue
    fi
    if [[ -d "$SOURCE_DIR/skills/$name" ]]; then
      backup_path "$path"
    fi
  done
}

log "Source directory: $SOURCE_DIR"
log "Backup directory: $BACKUP_ROOT"

# Claude Code
ensure_symlink "$SOURCE_DIR/CLAUDE.md" "${HOME}/.claude/CLAUDE.md"
ensure_symlink "$SOURCE_DIR/skills" "${HOME}/.claude/skills"
ensure_symlink "$SOURCE_DIR/settings.json" "${HOME}/.claude/settings.json"
ensure_symlink "$SOURCE_DIR/statusline-command.sh" "${HOME}/.claude/statusline-command.sh"

# Gemini
ensure_symlink "$SOURCE_DIR/CLAUDE.md" "${HOME}/.gemini/GEMINI.md"
ensure_symlink "$SOURCE_DIR/skills" "${HOME}/.gemini/skills"

# Copilot
ensure_symlink "$SOURCE_DIR/CLAUDE.md" "${HOME}/.copilot/copilot-instructions.md"
ensure_symlink "$SOURCE_DIR/skills" "${HOME}/.copilot/skills"
ensure_symlink "$SOURCE_DIR/AGENTS.md" "${HOME}/.copilot/AGENTS.md"

# Codex
cleanup_codex_skill_overrides
ensure_symlink "$SOURCE_DIR/AGENTS.md" "${HOME}/.codex/AGENTS.md"
ensure_symlink "$SOURCE_DIR/.codex/config.toml" "${HOME}/.codex/config.toml"
ensure_symlink "$SOURCE_DIR/.codex/agents" "${HOME}/.codex/agents"
ensure_symlink "$SOURCE_DIR/skills" "${HOME}/.codex/skills/skills"

log "Sync complete."
