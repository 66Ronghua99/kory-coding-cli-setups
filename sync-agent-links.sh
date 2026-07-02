#!/usr/bin/env bash
set -euo pipefail

SOURCE_DIR="$(cd "$(dirname "$0")" && pwd)"
SUPERPOWERS_DIR="${SUPERPOWERS_DIR:-$SOURCE_DIR/superpowers}"
SUPERPOWERS_REMOTE_URL="${SUPERPOWERS_REMOTE_URL:-https://github.com/obra/superpowers.git}"
SUPERPOWERS_BRANCH="${SUPERPOWERS_BRANCH:-main}"
KIMI_CODE_HOME="${KIMI_CODE_HOME:-$HOME/.kimi-code}"
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
DEPRECATED_CODEX_SKILLS=(
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

ensure_superpowers_repo() {
  command -v git >/dev/null 2>&1 || die "git is required to sync superpowers"
  [[ -n "$SUPERPOWERS_REMOTE_URL" ]] || die "Missing superpowers remote. Set SUPERPOWERS_REMOTE_URL or restore the default."

  if [[ ! -e "$SUPERPOWERS_DIR" ]]; then
    ensure_dir "$(dirname "$SUPERPOWERS_DIR")"
    run_cmd git clone --branch "$SUPERPOWERS_BRANCH" --single-branch "$SUPERPOWERS_REMOTE_URL" "$SUPERPOWERS_DIR"
  elif [[ ! -e "$SUPERPOWERS_DIR/.git" ]]; then
    die "Existing superpowers path is not a git repository: $SUPERPOWERS_DIR"
  else
    run_cmd git -C "$SUPERPOWERS_DIR" checkout -- \
      skills/brainstorming/SKILL.md \
      skills/writing-plans/SKILL.md
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

patch_humanize_codex_hooks_feature_name() {
  [[ "$HUMANIZE_SYNC" != "0" ]] || return 0
  local hooks_installer="$HUMANIZE_DIR/scripts/install-codex-hooks.sh"
  [[ -f "$hooks_installer" ]] || return 0

  local feature_name=""
  if command -v codex >/dev/null 2>&1; then
    if codex features list 2>/dev/null | awk '$1 == "hooks" { found = 1 } END { exit(found ? 0 : 1) }'; then
      feature_name="hooks"
    elif codex features list 2>/dev/null | awk '$1 == "codex_hooks" { found = 1 } END { exit(found ? 0 : 1) }'; then
      feature_name="codex_hooks"
    fi
  fi

  [[ -n "$feature_name" ]] || return 0

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] patch Humanize codex_hooks feature name to $feature_name in $hooks_installer"
    return 0
  fi

  command -v python3 >/dev/null 2>&1 || die "python3 is required to patch Humanize codex_hooks feature name"
  python3 - "$hooks_installer" "$feature_name" <<'PY'
import pathlib
import sys

path = pathlib.Path(sys.argv[1])
feature_name = sys.argv[2]
text = path.read_text(encoding="utf-8")
if "codex_hooks" in text:
    path.write_text(text.replace("codex_hooks", feature_name), encoding="utf-8")
PY
  log "Patched Humanize codex_hooks feature name to $feature_name: $hooks_installer"
}

patch_superpowers_local_only_policy() {
  local brainstorming_skill="$SUPERPOWERS_DIR/skills/brainstorming/SKILL.md"
  local writing_plans_skill="$SUPERPOWERS_DIR/skills/writing-plans/SKILL.md"

  if [[ ! -f "$brainstorming_skill" && ! -f "$writing_plans_skill" ]]; then
    return 0
  fi

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] patch Superpowers local-only docs policy in $SUPERPOWERS_DIR/skills"
    return 0
  fi

  command -v python3 >/dev/null 2>&1 || die "python3 is required to patch Superpowers local-only docs policy"
  python3 - "$brainstorming_skill" "$writing_plans_skill" <<'PY'
import pathlib
import re
import sys

brainstorming_path = pathlib.Path(sys.argv[1])
writing_plans_path = pathlib.Path(sys.argv[2])

if brainstorming_path.is_file():
    text = brainstorming_path.read_text(encoding="utf-8")
    text = text.replace(
        "6. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit",
        "6. **Write design doc** — save locally to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` without staging or committing it",
    )
    text = text.replace(
        "- Write the validated design (spec) to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`",
        "- Write the validated design (spec) locally to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md`; do not stage or commit it",
    )
    text = text.replace("Spec written and committed to", "Spec written locally to")
    brainstorming_path.write_text(text, encoding="utf-8")

if writing_plans_path.is_file():
    text = writing_plans_path.read_text(encoding="utf-8")
    text = re.sub(
        r"(\*\*Save plans to:\*\* `docs/superpowers/plans/YYYY-MM-DD-<feature-name>\.md`\n)"
        r"(?!- Do not stage or commit `docs/superpowers/`)",
        r"\1- Do not stage or commit `docs/superpowers/`, `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, or `artifacts/`.\n",
        text,
    )
    text = re.sub(r"(git add[^\n]*)\s+docs/superpowers/\S+", r"\1", text)
    writing_plans_path.write_text(text, encoding="utf-8")
PY
  log "Patched Superpowers local-only docs policy: $SUPERPOWERS_DIR/skills"
}

install_humanize_rlcr() {
  [[ "$HUMANIZE_SYNC" != "0" ]] || return 0
  run_cmd "$HUMANIZE_DIR/scripts/install-skill.sh" \
    --target both \
    --kimi-skills-dir "${SOURCE_DIR}/skills" \
    --codex-skills-dir "${SOURCE_DIR}/skills"
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

install_kimi_stop_hook_wrapper() {
  [[ "$HUMANIZE_SYNC" != "0" ]] || return 0
  local hooks_dir="${SOURCE_DIR}/skills/humanize/hooks"
  local wrapper="$hooks_dir/loop-kimi-stop-hook.sh"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] install Kimi Stop hook wrapper: $wrapper"
    return 0
  fi

  ensure_dir "$hooks_dir"

  cat > "$wrapper" <<'EOF'
#!/usr/bin/env bash
#
# Kimi native Stop hook adapter for Humanize RLCR.
#
# Kimi passes the hook event as JSON via stdin and expects:
#   exit 0  -> allow the stop
#   exit 2  -> block the stop (stderr is shown as the reason)
#
# Humanize's loop-codex-stop-hook.sh speaks the Claude Code hook protocol:
#   stdout contains JSON {"decision": "block", "reason": "..."} and exits 0.
# This wrapper converts between the two protocols.
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
CODEX_STOP_HOOK="$SCRIPT_DIR/loop-codex-stop-hook.sh"

TMP_OUTPUT="$(mktemp)"
trap 'rm -f "$TMP_OUTPUT"' EXIT

# The Codex/Claude hook reads stdin itself (it expects Claude-style hook JSON).
# It writes its decision JSON to stdout; we capture stdout while letting stderr
# flow through to Kimi so progress/review output is visible.
if ! "$CODEX_STOP_HOOK" >"$TMP_OUTPUT"; then
  echo "Humanize stop hook failed with exit code $?. Blocking exit." >&2
  exit 2
fi

# Parse the Claude-style decision from stdout.
DECISION=""
REASON=""
if command -v jq >/dev/null 2>&1; then
  DECISION="$(jq -r '.decision // empty' "$TMP_OUTPUT" 2>/dev/null || echo "")"
  REASON="$(jq -r '.reason // "Blocked by Humanize RLCR stop hook."' "$TMP_OUTPUT" 2>/dev/null || echo "Blocked by Humanize RLCR stop hook.")"
else
  # Minimal fallback if jq is missing: grep for the decision field.
  DECISION="$(grep -o '"decision"[[:space:]]*:[[:space:]]*"[^"]*"' "$TMP_OUTPUT" 2>/dev/null | head -1 | sed 's/.*"\([^"]*\)"$/\1/' || echo "")"
  REASON="Blocked by Humanize RLCR stop hook."
fi

if [[ "$DECISION" == "block" ]]; then
  echo "$REASON" >&2
  exit 2
fi

exit 0
EOF

  chmod +x "$wrapper"
  log "Installed Kimi Stop hook wrapper: $wrapper"
}

ensure_kimi_stop_hook_config() {
  [[ "$HUMANIZE_SYNC" != "0" ]] || return 0
  local kimi_config="${KIMI_CODE_HOME}/config.toml"
  local wrapper="${SOURCE_DIR}/skills/humanize/hooks/loop-kimi-stop-hook.sh"

  ensure_dir "$(dirname "$kimi_config")"

  if [[ "$DRY_RUN" -eq 1 ]]; then
    log "[dry-run] ensure Kimi Stop hook config in $kimi_config"
    return 0
  fi

  if [[ -f "$kimi_config" ]] && grep -Fq "$wrapper" "$kimi_config"; then
    log "OK Kimi Stop hook config: $kimi_config"
    return 0
  fi

  command -v python3 >/dev/null 2>&1 || die "python3 is required to update Kimi config"
  python3 - "$kimi_config" "$wrapper" <<'PY'
import pathlib
import sys

try:
    import tomllib
except ImportError:
    import tomli as tomllib
import toml

config_path = pathlib.Path(sys.argv[1])
hook_command = sys.argv[2]

data = {}
if config_path.exists():
    data = tomllib.loads(config_path.read_text(encoding="utf-8"))

hooks = data.setdefault("hooks", [])

already_registered = any(
    isinstance(h, dict) and h.get("event") == "Stop" and h.get("command") == hook_command
    for h in hooks
)

if not already_registered:
    hooks.append({
        "event": "Stop",
        "command": hook_command,
        "timeout": 600,
    })
    config_path.write_text(toml.dumps(data), encoding="utf-8")
PY
  log "Added Kimi Stop hook config: $kimi_config"
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
  cleanup_deprecated_codex_skills "$codex_skills_dir"

  local path
  for path in "$SOURCE_DIR/skills"/*; do
    [[ -e "$path" || -L "$path" ]] || continue
    local name
    name="$(basename "$path")"
    ensure_symlink "$path" "$codex_skills_dir/$name"
  done
}

cleanup_deprecated_codex_skills() {
  local codex_skills_dir="$1"
  local skill
  for skill in "${DEPRECATED_CODEX_SKILLS[@]}"; do
    local target="$codex_skills_dir/$skill"
    if [[ -e "$target" || -L "$target" ]]; then
      backup_path "$target"
    fi
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
  log "Kimi Code home: $KIMI_CODE_HOME"

  ensure_superpowers_repo
  ensure_humanize_repo
  patch_humanize_codex_hook_probe
  patch_humanize_codex_hooks_feature_name
  patch_superpowers_local_only_policy
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
  install_humanize_rlcr
  ensure_codex_skills_links

  # Kimi
  ensure_symlink "$SOURCE_DIR/AGENTS.md" "${KIMI_CODE_HOME}/AGENTS.md"
  ensure_symlink "$SOURCE_DIR/skills" "${KIMI_CODE_HOME}/skills"
  install_kimi_stop_hook_wrapper
  ensure_kimi_stop_hook_config

  log "Sync complete."
}

main "$@"
