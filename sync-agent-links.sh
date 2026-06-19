#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
SUPERPOWERS_DIR="${SUPERPOWERS_DIR:-$SOURCE_DIR/superpowers}"
SUPERPOWERS_REMOTE_URL="${SUPERPOWERS_REMOTE_URL:-https://github.com/obra/superpowers.git}"
SUPERPOWERS_BRANCH="${SUPERPOWERS_BRANCH:-main}"
HUMANIZE_SYNC="${HUMANIZE_SYNC:-1}"
HUMANIZE_DIR="${HUMANIZE_DIR:-$SOURCE_DIR/humanize}"
HUMANIZE_REMOTE_URL="${HUMANIZE_REMOTE_URL:-https://github.com/PolyArch/humanize.git}"
HUMANIZE_BRANCH="${HUMANIZE_BRANCH:-main}"
BACKUP_ROOT="${HOME}/.coding-cli-sync-backups/$(date +%Y%m%d_%H%M%S)"
DRY_RUN=0
SYNC_CODEX_CONFIG=0
CURATED_SUPERPOWERS_SKILLS=(
  using-superpowers
  brainstorming
  writing-plans
  executing-plans
  test-driven-development
  verification-before-completion
)

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
      --sync-codex-config)
        SYNC_CODEX_CONFIG=1
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
  command -v git >/dev/null 2>&1 || die "git is required to sync superpowers"
  [[ -n "$SUPERPOWERS_REMOTE_URL" ]] || die "Missing superpowers remote. Set SUPERPOWERS_REMOTE_URL or restore the default."

  if [[ ! -e "$SUPERPOWERS_DIR" ]]; then
    ensure_dir "$(dirname "$SUPERPOWERS_DIR")"
    run_cmd git clone --branch "$SUPERPOWERS_BRANCH" --single-branch "$SUPERPOWERS_REMOTE_URL" "$SUPERPOWERS_DIR"
  elif [[ ! -e "$SUPERPOWERS_DIR/.git" ]]; then
    die "Existing superpowers path is not a git repository: $SUPERPOWERS_DIR"
  else
    run_cmd git -C "$SUPERPOWERS_DIR" checkout "$SUPERPOWERS_BRANCH"
    run_cmd git -C "$SUPERPOWERS_DIR" pull --ff-only origin "$SUPERPOWERS_BRANCH"
  fi

  [[ -d "$SUPERPOWERS_DIR/skills" ]] || die "Missing superpowers skills directory: $SUPERPOWERS_DIR/skills."
}

ensure_humanize_repo() {
  [[ "$HUMANIZE_SYNC" != "0" ]] || return 0
  command -v git >/dev/null 2>&1 || die "git is required to sync humanize"
  [[ -n "$HUMANIZE_REMOTE_URL" ]] || die "Missing Humanize remote. Set HUMANIZE_REMOTE_URL or HUMANIZE_SYNC=0."

  if [[ ! -e "$HUMANIZE_DIR" ]]; then
    ensure_dir "$(dirname "$HUMANIZE_DIR")"
    run_cmd git clone --branch "$HUMANIZE_BRANCH" --single-branch "$HUMANIZE_REMOTE_URL" "$HUMANIZE_DIR"
    [[ "$DRY_RUN" -eq 1 ]] && return 0
  elif [[ ! -e "$HUMANIZE_DIR/.git" ]]; then
    die "Existing humanize path is not a git repository: $HUMANIZE_DIR"
  else
    if [[ -e "$HUMANIZE_DIR/scripts/install-codex-hooks.sh" ]]; then
      run_cmd git -C "$HUMANIZE_DIR" checkout -- scripts/install-codex-hooks.sh
    fi
    run_cmd git -C "$HUMANIZE_DIR" checkout "$HUMANIZE_BRANCH"
    run_cmd git -C "$HUMANIZE_DIR" pull --ff-only origin "$HUMANIZE_BRANCH"
  fi

  [[ -x "$HUMANIZE_DIR/scripts/install-skill.sh" ]] || die "Missing executable Humanize installer: $HUMANIZE_DIR/scripts/install-skill.sh."
}

patch_humanize_codex_hook_probe() {
  [[ "$HUMANIZE_SYNC" != "0" ]] || return 0
  local hooks_installer="$HUMANIZE_DIR/scripts/install-codex-hooks.sh"
  [[ -f "$hooks_installer" ]] || return 0

  local old_probe="codex features list 2>/dev/null | grep -qE '^codex_hooks[[:space:]]'"
  if ! grep -Fq "$old_probe" "$hooks_installer"; then
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] patch Humanize codex_hooks feature probe in $hooks_installer"
    return 0
  fi

  command -v python3 >/dev/null 2>&1 || die "python3 is required to patch Humanize codex_hooks probe"
  python3 - "$hooks_installer" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
old = "codex features list 2>/dev/null | grep -qE '^codex_hooks[[:space:]]'"
new = "codex features list 2>/dev/null | awk '$1 == \"codex_hooks\" { found = 1 } END { exit(found ? 0 : 1) }'"
if old in text:
    path.write_text(text.replace(old, new), encoding="utf-8")
PY
  log "Patched Humanize codex_hooks feature probe: $hooks_installer"
}

install_humanize_codex_rlcr() {
  [[ "$HUMANIZE_SYNC" != "0" ]] || return 0
  run_cmd "$HUMANIZE_DIR/scripts/install-skill.sh" --target codex
  sanitize_codex_hooks_config
}

sanitize_codex_hooks_config() {
  [[ "$HUMANIZE_SYNC" != "0" ]] || return 0
  local hooks_file="${HOME}/.codex/hooks.json"
  [[ -f "$hooks_file" ]] || return 0

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] remove unsupported top-level description from $hooks_file"
    return 0
  fi

  command -v python3 >/dev/null 2>&1 || die "python3 is required to sanitize Codex hooks config"
  python3 - "$hooks_file" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
if isinstance(data, dict) and "description" in data:
    data.pop("description", None)
    path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
}

cleanup_legacy_superpowers_namespace() {
  local legacy_path="$SOURCE_DIR/skills/superpowers"
  if [[ -e "$legacy_path" || -L "$legacy_path" ]]; then
    backup_path "$legacy_path"
  fi
}

ensure_curated_superpowers_skills() {
  ensure_dir "$SOURCE_DIR/skills"
  cleanup_legacy_superpowers_namespace

  local skill
  for skill in "${CURATED_SUPERPOWERS_SKILLS[@]}"; do
    local source_skill="$SUPERPOWERS_DIR/skills/$skill"
    [[ -d "$source_skill" ]] || die "Missing curated superpowers skill: $source_skill"
    ensure_symlink "$source_skill" "$SOURCE_DIR/skills/$skill"
  done
}

ensure_codex_skills_links() {
  local codex_skills_dir="${HOME}/.codex/skills"
  ensure_dir "$codex_skills_dir"

  local path
  for path in "$SOURCE_DIR/skills"/*; do
    [[ -e "$path" || -L "$path" ]] || continue
    local name
    name="$(basename "$path")"
    ensure_symlink "$path" "$codex_skills_dir/$name"
  done
}

ensure_codex_config_file() {
  local source_config="$SOURCE_DIR/.codex/config.toml"
  local target_config="${HOME}/.codex/config.toml"

  ensure_dir "$(dirname "$target_config")"
  [[ -f "$source_config" ]] || die "Missing source Codex config: $source_config"

  if [[ "$SYNC_CODEX_CONFIG" -eq 1 ]]; then
    if [[ -L "$target_config" ]]; then
      run_cmd rm "$target_config"
    fi
    run_cmd cp "$source_config" "$target_config"
    log "Copied Codex config: $source_config -> $target_config"
    return
  fi

  if [[ -L "$target_config" ]]; then
    local linked_config
    linked_config="$(readlink "$target_config")"
    [[ -f "$linked_config" ]] || die "Codex config symlink points to a missing file: $target_config -> $linked_config"
    if [[ "$DRY_RUN" -eq 1 ]]; then
      log "[dry-run] replace Codex config symlink with regular file copied from $linked_config"
      return
    fi
    local tmp_config
    tmp_config="$(mktemp "${target_config}.tmp.XXXXXX")"
    cp "$linked_config" "$tmp_config"
    rm "$target_config"
    mv "$tmp_config" "$target_config"
    log "Converted Codex config symlink to regular file: $target_config"
    return
  fi

  if [[ -e "$target_config" ]]; then
    log "Keeping existing Codex config file: $target_config"
  else
    log "Codex config file missing; pass --sync-codex-config to create it from $source_config"
  fi
}

main() {
  parse_args "$@"

  log "Source directory: $SOURCE_DIR"
  log "Superpowers directory: $SUPERPOWERS_DIR"
  log "Superpowers remote: $SUPERPOWERS_REMOTE_URL"
  log "Superpowers branch: $SUPERPOWERS_BRANCH"
  log "Humanize sync: $HUMANIZE_SYNC"
  if [[ "$HUMANIZE_SYNC" != "0" ]]; then
    log "Humanize directory: $HUMANIZE_DIR"
    log "Humanize remote: $HUMANIZE_REMOTE_URL"
    log "Humanize branch: $HUMANIZE_BRANCH"
  fi
  log "Backup directory: $BACKUP_ROOT"

  ensure_superpowers_repo
  ensure_humanize_repo
  patch_humanize_codex_hook_probe
  ensure_curated_superpowers_skills

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
  ensure_symlink "$SOURCE_DIR/AGENTS.md" "${HOME}/.codex/AGENTS.md"
  ensure_codex_config_file
  ensure_symlink "$SOURCE_DIR/.codex/agents" "${HOME}/.codex/agents"
  ensure_codex_skills_links
  install_humanize_codex_rlcr

  log "Sync complete."
}

main "$@"
