#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
KIMI_CODE_HOME="${KIMI_CODE_HOME:-$HOME/.kimi-code}"
OMP_AGENT_HOME="${PI_CODING_AGENT_DIR:-$HOME/.omp/agent}"
BACKUP_ROOT="${HOME}/.coding-cli-sync-backups/$(date +%Y%m%d_%H%M%S)"
DRY_RUN=0
SYNC_CODEX_CONFIG=0
REQUIRED_LOCAL_SKILLS=(
  brainstorming
  writing-plans
  executing-plans
)
RETIRED_SKILLS=(
  using-superpowers
  test-driven-development
  verification-before-completion
  superman
  code-simplifier
  harness-doc-health
  content-creator-collab
  humanize
  humanize-gen-plan
  humanize-refine-plan
  humanize-rlcr
)
LEGACY_CODEX_SKILLS=(
  harness-lint-test-design
  harness-refactor
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

validate_local_skills() {
  local skill
  for skill in "${REQUIRED_LOCAL_SKILLS[@]}"; do
    local skill_dir="$SOURCE_DIR/skills/$skill"
    local skill_file="$skill_dir/SKILL.md"
    [[ -d "$skill_dir" && ! -L "$skill_dir" ]] || die "Local skill must be a real directory: $skill_dir"
    [[ -f "$skill_file" ]] || die "Missing local skill file: $skill_file"

    local declared_name=""
    local line
    while IFS= read -r line; do
      case "$line" in
        "name: "*)
          declared_name="${line#name: }"
          break
          ;;
      esac
    done < "$skill_file"
    [[ "$declared_name" == "$skill" ]] || die "Invalid local skill name in $skill_file: expected $skill, found ${declared_name:-<missing>}"
  done
  log "Validated local skills: ${REQUIRED_LOCAL_SKILLS[*]}"
}

cleanup_codex_humanize_hook() {
  local hooks_file="$HOME/.codex/hooks.json"
  [[ -f "$hooks_file" ]] || return 0

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] remove managed Humanize hooks from $hooks_file"
    return 0
  fi

  command -v python3 >/dev/null 2>&1 || die "python3 is required to clean Codex hooks config"
  python3 - "$hooks_file" <<'PY'
import json
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))
if not isinstance(data, dict):
    raise SystemExit(f"Invalid Codex hooks config root: {path}")

hooks = data.get("hooks")
if hooks is None:
    raise SystemExit(0)
if not isinstance(hooks, dict):
    raise SystemExit(f"Invalid Codex hooks map: {path}")

stop_groups = hooks.get("Stop")
if stop_groups is None:
    raise SystemExit(0)
if not isinstance(stop_groups, list):
    raise SystemExit(f"Invalid Codex Stop hooks list: {path}")

changed = False
kept_groups = []
for group in stop_groups:
    if not isinstance(group, dict):
        kept_groups.append(group)
        continue
    commands = group.get("hooks")
    if not isinstance(commands, list):
        kept_groups.append(group)
        continue
    kept_commands = []
    for hook in commands:
        managed = (
            isinstance(hook, dict)
            and hook.get("type") == "command"
            and "/skills/humanize/" in str(hook.get("command", ""))
        )
        if managed:
            changed = True
        else:
            kept_commands.append(hook)
    if kept_commands:
        if len(kept_commands) != len(commands):
            group = dict(group)
            group["hooks"] = kept_commands
        kept_groups.append(group)
    elif commands:
        changed = True

if not changed:
    raise SystemExit(0)
if kept_groups:
    hooks["Stop"] = kept_groups
else:
    hooks.pop("Stop", None)
if not hooks:
    data.pop("hooks", None)
path.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
PY
  log "Removed managed Humanize hooks from $hooks_file"
}

cleanup_kimi_humanize_hook() {
  local config_file="$KIMI_CODE_HOME/config.toml"
  [[ -f "$config_file" ]] || return 0

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] remove managed Humanize hooks from $config_file"
    return 0
  fi

  command -v python3 >/dev/null 2>&1 || die "python3 is required to clean Kimi hooks config"
  python3 - "$config_file" <<'PY'
import pathlib
import re
import sys

try:
    import tomllib
except ImportError:
    import tomli as tomllib

path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
tomllib.loads(text)
lines = text.splitlines(keepends=True)
blocks = []
start = 0
for index, line in enumerate(lines):
    if index and line.startswith("["):
        blocks.append(lines[start:index])
        start = index
blocks.append(lines[start:])

event_pattern = re.compile(r'^event\s*=\s*["\']Stop["\']\s*$', re.MULTILINE)
command_pattern = re.compile(r'^command\s*=\s*["\']([^"\']+)["\']\s*$', re.MULTILINE)
kept = []
changed = False
for block in blocks:
    body = "".join(block)
    managed = False
    if block and block[0].strip() == "[[hooks]]" and event_pattern.search(body):
        command = command_pattern.search(body)
        managed = bool(command and "/skills/humanize/" in command.group(1))
    if managed:
        changed = True
    else:
        kept.extend(block)

if changed:
    path.write_text("".join(kept), encoding="utf-8")
PY
  log "Removed managed Humanize hooks from $config_file"
}

cleanup_retired_assets() {
  local skill
  backup_path "$SOURCE_DIR/humanize"
  backup_path "$SOURCE_DIR/skills/superpowers"
  for skill in "${RETIRED_SKILLS[@]}"; do
    backup_path "$SOURCE_DIR/skills/$skill"
    backup_path "$HOME/.codex/skills/$skill"
  done
  for skill in "${LEGACY_CODEX_SKILLS[@]}"; do
    backup_path "$HOME/.codex/skills/$skill"
  done
  cleanup_codex_humanize_hook
  cleanup_kimi_humanize_hook
}


is_retired_skill() {
  local name="$1"
  local retired
  for retired in "${RETIRED_SKILLS[@]}"; do
    [[ "$name" == "$retired" ]] && return 0
  done
  return 1
}

ensure_codex_skills_links() {
  local codex_skills_dir="$HOME/.codex/skills"
  ensure_dir "$codex_skills_dir"

  local path
  for path in "$SOURCE_DIR/skills"/*; do
    [[ -e "$path" || -L "$path" ]] || continue
    local name
    name="$(basename "$path")"
    is_retired_skill "$name" && continue
    ensure_symlink "$path" "$codex_skills_dir/$name"
  done
}

ensure_codex_config_file() {
  local source_config="$SOURCE_DIR/.codex/config.toml"
  local target_config="$HOME/.codex/config.toml"

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
  log "Backup directory: $BACKUP_ROOT"
  log "Kimi Code home: $KIMI_CODE_HOME"
  log "OMP agent home: $OMP_AGENT_HOME"

  validate_local_skills
  cleanup_retired_assets

  # Claude Code
  ensure_symlink "$SOURCE_DIR/AGENTS.md" "$HOME/.claude/CLAUDE.md"
  ensure_symlink "$SOURCE_DIR/skills" "$HOME/.claude/skills"
  ensure_symlink "$SOURCE_DIR/settings.json" "$HOME/.claude/settings.json"
  ensure_symlink "$SOURCE_DIR/statusline-command.sh" "$HOME/.claude/statusline-command.sh"

  # Gemini
  ensure_symlink "$SOURCE_DIR/AGENTS.md" "$HOME/.gemini/GEMINI.md"
  ensure_symlink "$SOURCE_DIR/skills" "$HOME/.gemini/skills"

  # Copilot
  ensure_symlink "$SOURCE_DIR/AGENTS.md" "$HOME/.copilot/copilot-instructions.md"
  ensure_symlink "$SOURCE_DIR/skills" "$HOME/.copilot/skills"
  ensure_symlink "$SOURCE_DIR/AGENTS.md" "$HOME/.copilot/AGENTS.md"

  # Codex
  ensure_symlink "$SOURCE_DIR/AGENTS.md" "$HOME/.codex/AGENTS.md"
  ensure_codex_config_file
  ensure_symlink "$SOURCE_DIR/.codex/agents" "$HOME/.codex/agents"
  ensure_codex_skills_links

  # Kimi
  ensure_symlink "$SOURCE_DIR/AGENTS.md" "$KIMI_CODE_HOME/AGENTS.md"
  ensure_symlink "$SOURCE_DIR/skills" "$KIMI_CODE_HOME/skills"

  # Oh My Pi
  ensure_symlink "$SOURCE_DIR/AGENTS.md" "$OMP_AGENT_HOME/AGENTS.md"
  ensure_symlink "$SOURCE_DIR/skills" "$OMP_AGENT_HOME/skills"

  log "Sync complete."
}

main "$@"
