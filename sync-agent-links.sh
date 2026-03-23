#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
SUPERPOWERS_DIR="${SUPERPOWERS_DIR:-$SOURCE_DIR/superpowers}"
SUPERPOWERS_SKILLS_LINK="${SUPERPOWERS_SKILLS_LINK:-$SOURCE_DIR/skills/superpowers}"
BACKUP_ROOT="${HOME}/.coding-cli-sync-backups/$(date +%Y%m%d_%H%M%S)"
DRY_RUN=0

log() {
  printf '%s\n' "$*"
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

quote_cmd() {
  local quoted=()
  local arg
  for arg in "$@"; do
    quoted+=("$(printf '%q' "$arg")")
  done
  printf '%s' "${quoted[*]}"
}

run_cmd() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    printf '[dry-run] %s\n' "$(quote_cmd "$@")"
    return 0
  fi
  "$@"
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --dry-run)
        DRY_RUN=1
        ;;
      --update-superpowers)
        die "--update-superpowers is no longer supported; run 'git submodule update --remote superpowers' manually first"
        ;;
      *)
        die "Unknown argument: $1"
        ;;
    esac
    shift
  done
}

ensure_dir() {
  local dir="$1"
  if [[ ! -d "$dir" ]]; then
    run_cmd mkdir -p "$dir"
  fi
}

backup_path() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    ensure_dir "$BACKUP_ROOT"
    local rel="${target#/}"
    local backup_target="$BACKUP_ROOT/$rel"
    ensure_dir "$(dirname "$backup_target")"
    run_cmd mv "$target" "$backup_target"
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

  run_cmd ln -s "$source" "$target"
  log "Linked $target -> $source"
}

ensure_superpowers_repo() {
  if [[ ! -e "$SUPERPOWERS_DIR" ]]; then
    die "Missing superpowers checkout: $SUPERPOWERS_DIR. Run 'git submodule update --init --recursive'."
  fi

  if [[ ! -e "$SUPERPOWERS_DIR/.git" ]]; then
    die "Existing superpowers path is not a git repository: $SUPERPOWERS_DIR"
  fi

  [[ -d "$SUPERPOWERS_DIR/skills" ]] || die "Missing superpowers skills directory: $SUPERPOWERS_DIR/skills. Run 'git submodule update --init --recursive'."
}

ensure_superpowers_skills_link() {
  ensure_dir "$(dirname "$SUPERPOWERS_SKILLS_LINK")"
  ensure_symlink "$SUPERPOWERS_DIR/skills" "$SUPERPOWERS_SKILLS_LINK"
}

cleanup_codex_skill_overrides() {
  local codex_skills_dir="${HOME}/.codex/skills"
  [[ -d "$codex_skills_dir" ]] || return 0

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

main() {
  parse_args "$@"

  log "Source directory: $SOURCE_DIR"
  log "Superpowers directory: $SUPERPOWERS_DIR"
  log "Backup directory: $BACKUP_ROOT"

  ensure_superpowers_repo
  ensure_superpowers_skills_link

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
}

main "$@"
