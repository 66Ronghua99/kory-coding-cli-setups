#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CURATED_SKILLS=(
  brainstorming
  writing-plans
  executing-plans
)
LOCAL_SKILL_DIRS=(
  harness-init
  frontend-slides-2.0.0
  grill-with-docs
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

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_exists() {
  local path="$1"
  [[ -e "$path" || -L "$path" ]] || fail "Expected path to exist: $path"
}

assert_not_exists() {
  local path="$1"
  [[ ! -e "$path" && ! -L "$path" ]] || fail "Expected path to be absent: $path"
}

assert_regular_file() {
  local path="$1"
  [[ -f "$path" && ! -L "$path" ]] || fail "Expected regular file: $path"
}

assert_real_directory() {
  local path="$1"
  [[ -d "$path" && ! -L "$path" ]] || fail "Expected real directory: $path"
}

assert_file_contains() {
  local path="$1"
  local expected="$2"
  grep -Fq -- "$expected" "$path" || fail "Expected $path to contain: $expected"
}

assert_file_not_contains() {
  local path="$1"
  local unexpected="$2"
  if grep -Fq -- "$unexpected" "$path"; then
    fail "Expected $path not to contain: $unexpected"
  fi
}

assert_file_not_has_line() {
  local path="$1"
  local unexpected="$2"
  if grep -Fxq -- "$unexpected" "$path"; then
    fail "Expected $path not to contain line: $unexpected"
  fi
}

assert_symlink_target() {
  local path="$1"
  local expected="$2"
  [[ -L "$path" ]] || fail "Expected symlink: $path"
  local actual
  actual="$(readlink "$path")"
  [[ "$actual" == "$expected" ]] || fail "Expected $path -> $expected, got $actual"
}


make_fake_source() {
  local source="$1"
  mkdir -p "$source/.codex/agents"
  cp "$REPO_ROOT/sync-agent-links.sh" "$source/sync-agent-links.sh"
  chmod +x "$source/sync-agent-links.sh"
  cat > "$source/AGENTS.md" <<'EOF'
# AGENTS
EOF
  cat > "$source/settings.json" <<'EOF'
{}
EOF
  cat > "$source/statusline-command.sh" <<'EOF'
#!/usr/bin/env bash
echo ok
EOF
  chmod +x "$source/statusline-command.sh"
  cat > "$source/.codex/config.toml" <<'EOF'
model = "gpt-test"
EOF
  cat > "$source/.codex/agents/explorer.toml" <<'EOF'
description = "explorer"
EOF

  local skill
  mkdir -p "$source/skills"
  for skill in "${CURATED_SKILLS[@]}"; do
    cp -R "$REPO_ROOT/skills/$skill" "$source/skills/$skill"
  done
  local skill_dir skill_name
  for skill_dir in "${LOCAL_SKILL_DIRS[@]}"; do
    mkdir -p "$source/skills/$skill_dir"
    case "$skill_dir" in
      harness-init) skill_name="harness:init" ;;
      frontend-slides-2.0.0) skill_name="frontend-slides" ;;
      grill-with-docs) skill_name="grill-with-docs" ;;
      *) fail "Unexpected local skill fixture: $skill_dir" ;;
    esac
    cat > "$source/skills/$skill_dir/SKILL.md" <<EOF
---
name: $skill_name
description: local fixture
---
EOF
  done
}

run_sync() {
  local source="$1"
  local home_dir="$2"
  shift 2

  HOME="$home_dir" \
    PI_CODING_AGENT_DIR="${OMP_TEST_AGENT_HOME:-$home_dir/.omp/agent}" \
    bash "$source/sync-agent-links.sh" "$@"
}

assert_local_skill_sources() {
  local source="$1"
  local skill
  for skill in "${CURATED_SKILLS[@]}"; do
    assert_real_directory "$source/skills/$skill"
    assert_exists "$source/skills/$skill/SKILL.md"
  done
}

assert_canonical_instruction_links() {
  local source="$1"
  local home_dir="$2"
  local omp_home="${3:-$home_dir/.omp/agent}"
  assert_symlink_target "$home_dir/.claude/CLAUDE.md" "$source/AGENTS.md"
  assert_symlink_target "$home_dir/.gemini/GEMINI.md" "$source/AGENTS.md"
  assert_symlink_target "$home_dir/.copilot/copilot-instructions.md" "$source/AGENTS.md"
  assert_symlink_target "$home_dir/.copilot/AGENTS.md" "$source/AGENTS.md"
  assert_symlink_target "$home_dir/.codex/AGENTS.md" "$source/AGENTS.md"
  assert_symlink_target "$home_dir/.kimi-code/AGENTS.md" "$source/AGENTS.md"
  assert_symlink_target "$omp_home/AGENTS.md" "$source/AGENTS.md"
  assert_symlink_target "$omp_home/skills" "$source/skills"
}

seed_retired_assets() {
  local source="$1"
  local home_dir="$2"
  local skill

  mkdir -p "$source/humanize/.git" "$home_dir/.codex/skills" "$home_dir/.codex"
  printf 'legacy checkout\n' > "$source/humanize/VERSION"
  for skill in "${RETIRED_SKILLS[@]}"; do
    mkdir -p "$source/skills/$skill" "$home_dir/.codex/skills/$skill"
    printf 'legacy\n' > "$source/skills/$skill/SKILL.md"
    printf 'legacy\n' > "$home_dir/.codex/skills/$skill/SKILL.md"
  done
  mkdir -p "$source/skills/humanize/hooks" "$home_dir/.kimi-code"
  cat > "$home_dir/.codex/hooks.json" <<EOF
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {"type": "command", "command": "$source/skills/humanize/hooks/loop-codex-stop-hook.sh"},
          {"type": "command", "command": "/keep/unknown-stop-hook.sh"}
        ]
      }
    ],
    "Notification": [
      {"hooks": [{"type": "command", "command": "/keep/notification.sh"}]}
    ]
  }
}
EOF
  cat > "$home_dir/.kimi-code/config.toml" <<EOF
[[hooks]]
event = "Stop"
command = "$source/skills/humanize/hooks/loop-kimi-stop-hook.sh"
timeout = 600

[[hooks]]
event = "Stop"
command = "/keep/unknown-kimi-hook.sh"
timeout = 30

[loop_control]
max_retries_per_step = 3
EOF
}

test_sync_links_local_skills_to_all_agents() {
  local tempdir source home_dir
  tempdir="$(mktemp -d)"
  source="$tempdir/source"
  home_dir="$tempdir/home"
  make_fake_source "$source"
  mkdir -p "$home_dir"

  run_sync "$source" "$home_dir"

  assert_local_skill_sources "$source"
  assert_not_exists "$source/superpowers"
  assert_canonical_instruction_links "$source" "$home_dir"
  assert_symlink_target "$home_dir/.claude/skills" "$source/skills"
  assert_symlink_target "$home_dir/.gemini/skills" "$source/skills"
  assert_symlink_target "$home_dir/.copilot/skills" "$source/skills"
  assert_symlink_target "$home_dir/.kimi-code/skills" "$source/skills"
  local skill
  for skill in "${CURATED_SKILLS[@]}"; do
    assert_symlink_target "$home_dir/.codex/skills/$skill" "$source/skills/$skill"
  done
  assert_exists "$home_dir/.codex/skills/executing-plans/scripts/run-codex-review.sh"
  assert_exists "$home_dir/.codex/skills/executing-plans/scripts/run-codex-review.ps1"
  assert_exists "$home_dir/.codex/skills/harness-init/SKILL.md"
  assert_exists "$home_dir/.codex/skills/frontend-slides-2.0.0/SKILL.md"
  assert_exists "$home_dir/.codex/skills/grill-with-docs/SKILL.md"
  local retired
  for retired in "${RETIRED_SKILLS[@]}"; do
    assert_not_exists "$source/skills/$retired"
    assert_not_exists "$home_dir/.codex/skills/$retired"
  done
}

test_local_skills_are_self_contained() {
  assert_real_directory "$REPO_ROOT/skills/brainstorming"
  assert_real_directory "$REPO_ROOT/skills/writing-plans"
  assert_real_directory "$REPO_ROOT/skills/executing-plans"
  assert_file_contains "$REPO_ROOT/skills/executing-plans/SKILL.md" 'name: executing-plans'
  assert_file_contains "$REPO_ROOT/skills/executing-plans/SKILL.md" 'Never install or depend on hooks'
  assert_file_contains "$REPO_ROOT/skills/brainstorming/SKILL.md" 'save locally to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` without staging or committing it'
  assert_file_contains "$REPO_ROOT/skills/writing-plans/SKILL.md" 'Do not stage or commit `docs/superpowers/`, `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, or `artifacts/`.'

  local forbidden
  for forbidden in \
    'superpowers:using-git-worktrees' \
    'superpowers:subagent-driven-development' \
    'superpowers:executing-plans' \
    'elements-of-style:' \
    'Commit the design document to git' \
    'git add ' \
    'git commit ' \
    'https://github.com/obra/superpowers' \
    'https://primeradiant.com'; do
    assert_file_not_contains "$REPO_ROOT/skills/brainstorming/SKILL.md" "$forbidden"
    assert_file_not_contains "$REPO_ROOT/skills/writing-plans/SKILL.md" "$forbidden"
  done
  assert_file_not_contains "$REPO_ROOT/skills/brainstorming/scripts/server.cjs" 'https://github.com/obra/superpowers'
  assert_file_not_contains "$REPO_ROOT/skills/brainstorming/scripts/server.cjs" 'https://primeradiant.com'
  assert_file_not_contains "$REPO_ROOT/skills/brainstorming/scripts/server.cjs" 'SUPERPOWERS_VERSION'
}

test_missing_local_skill_fails_before_target_mutation() {
  local tempdir source home_dir
  tempdir="$(mktemp -d)"
  source="$tempdir/source"
  home_dir="$tempdir/home"
  make_fake_source "$source"
  rm -rf "$source/skills/brainstorming"
  mkdir -p "$home_dir"

  if run_sync "$source" "$home_dir" >"$tempdir/out" 2>"$tempdir/err"; then
    fail "Expected sync to fail when a required local skill is missing"
  fi

  assert_file_contains "$tempdir/err" "Local skill must be a real directory"
  assert_not_exists "$home_dir/.claude"
}

test_invalid_local_skill_name_fails_before_target_mutation() {
  local tempdir source home_dir
  tempdir="$(mktemp -d)"
  source="$tempdir/source"
  home_dir="$tempdir/home"
  make_fake_source "$source"
  printf '%s\n' '---' 'name: wrong-name' '---' > "$source/skills/brainstorming/SKILL.md"
  mkdir -p "$home_dir"

  if run_sync "$source" "$home_dir" >"$tempdir/out" 2>"$tempdir/err"; then
    fail "Expected sync to fail when a local skill name is invalid"
  fi

  assert_file_contains "$tempdir/err" "Invalid local skill name"
  assert_not_exists "$home_dir/.claude"
}

test_sync_removes_only_managed_retired_assets_and_humanize_hooks() {
  local tempdir source home_dir
  tempdir="$(mktemp -d)"
  source="$tempdir/source"
  home_dir="$tempdir/home"
  make_fake_source "$source"
  mkdir -p "$home_dir"
  seed_retired_assets "$source" "$home_dir"

  run_sync "$source" "$home_dir"

  assert_not_exists "$source/humanize"
  local retired
  for retired in "${RETIRED_SKILLS[@]}"; do
    assert_not_exists "$source/skills/$retired"
    assert_not_exists "$home_dir/.codex/skills/$retired"
  done
  assert_file_not_contains "$home_dir/.codex/hooks.json" '/skills/humanize/'
  assert_file_contains "$home_dir/.codex/hooks.json" '/keep/unknown-stop-hook.sh'
  assert_file_contains "$home_dir/.codex/hooks.json" '/keep/notification.sh'
  assert_file_not_contains "$home_dir/.kimi-code/config.toml" '/skills/humanize/'
  assert_file_contains "$home_dir/.kimi-code/config.toml" '/keep/unknown-kimi-hook.sh'
  assert_file_contains "$home_dir/.kimi-code/config.toml" 'max_retries_per_step = 3'
}

test_rerun_is_idempotent_when_links_are_correct() {
  local tempdir source home_dir
  tempdir="$(mktemp -d)"
  source="$tempdir/source"
  home_dir="$tempdir/home"
  make_fake_source "$source"
  mkdir -p "$home_dir"

  run_sync "$source" "$home_dir"
  run_sync "$source" "$home_dir"

  assert_not_exists "$home_dir/.coding-cli-sync-backups"
}

test_codex_config_is_not_overwritten_by_default() {
  local tempdir source home_dir
  tempdir="$(mktemp -d)"
  source="$tempdir/source"
  home_dir="$tempdir/home"
  make_fake_source "$source"
  mkdir -p "$home_dir/.codex"
  printf 'local-config\n' > "$home_dir/.codex/config.toml"

  run_sync "$source" "$home_dir"

  assert_regular_file "$home_dir/.codex/config.toml"
  assert_file_contains "$home_dir/.codex/config.toml" local-config
  assert_file_not_contains "$home_dir/.codex/config.toml" 'model = "gpt-test"'
}

test_codex_config_can_be_copied_with_explicit_flag() {
  local tempdir source home_dir
  tempdir="$(mktemp -d)"
  source="$tempdir/source"
  home_dir="$tempdir/home"
  make_fake_source "$source"
  mkdir -p "$home_dir/.codex"
  printf 'local-config\n' > "$home_dir/.codex/config.toml"

  run_sync "$source" "$home_dir" --sync-codex-config

  assert_regular_file "$home_dir/.codex/config.toml"
  assert_file_contains "$home_dir/.codex/config.toml" 'model = "gpt-test"'
  assert_file_not_contains "$home_dir/.codex/config.toml" local-config
}

test_superpowers_environment_is_ignored() {
  local tempdir source home_dir
  tempdir="$(mktemp -d)"
  source="$tempdir/source"
  home_dir="$tempdir/home"
  make_fake_source "$source"
  mkdir -p "$home_dir"

  SUPERPOWERS_REMOTE_URL="$tempdir/does-not-exist.git" run_sync "$source" "$home_dir"

  assert_not_exists "$source/superpowers"
  assert_symlink_target "$home_dir/.codex/skills/brainstorming" "$source/skills/brainstorming"
}


test_pi_coding_agent_dir_override() {
  local tempdir source home_dir omp_home
  tempdir="$(mktemp -d)"
  source="$tempdir/source"
  home_dir="$tempdir/home"
  omp_home="$tempdir/omp-agent"
  make_fake_source "$source"
  mkdir -p "$home_dir"

  OMP_TEST_AGENT_HOME="$omp_home" run_sync "$source" "$home_dir"

  assert_canonical_instruction_links "$source" "$home_dir" "$omp_home"
  assert_not_exists "$home_dir/.omp/agent"
}

test_kimi_code_home_override() {
  local tempdir source home_dir kimi_home
  tempdir="$(mktemp -d)"
  source="$tempdir/source"
  home_dir="$tempdir/home"
  kimi_home="$tempdir/kimi-home"
  make_fake_source "$source"
  mkdir -p "$home_dir"

  HOME="$home_dir" \
    KIMI_CODE_HOME="$kimi_home" \
    PI_CODING_AGENT_DIR="$home_dir/.omp/agent" \
    bash "$source/sync-agent-links.sh"

  assert_symlink_target "$kimi_home/AGENTS.md" "$source/AGENTS.md"
  assert_symlink_target "$kimi_home/skills" "$source/skills"
  assert_not_exists "$home_dir/.kimi-code"
}

test_dry_run_does_not_relink_retired_skills() {
  local tempdir source home_dir
  tempdir="$(mktemp -d)"
  source="$tempdir/source"
  home_dir="$tempdir/home"
  make_fake_source "$source"
  mkdir -p "$home_dir"
  run_sync "$source" "$home_dir" >/dev/null
  seed_retired_assets "$source" "$home_dir"

  run_sync "$source" "$home_dir" --dry-run >"$tempdir/out"

  assert_file_not_contains "$tempdir/out" "Linked $home_dir/.codex/skills/using-superpowers"
}

test_repo_ignore_rules_track_local_skills() {
  assert_file_not_contains "$REPO_ROOT/.gitignore" "/skills/brainstorming"
  assert_file_not_contains "$REPO_ROOT/.gitignore" "/skills/writing-plans"
  assert_file_not_has_line "$REPO_ROOT/.gitignore" "superpowers/"
  assert_file_not_contains "$REPO_ROOT/.gitignore" "/humanize/"
  assert_file_not_contains "$REPO_ROOT/.gitignore" "/skills/humanize*"
  assert_file_not_contains "$REPO_ROOT/.gitignore" "/skills/using-superpowers"
  assert_file_not_contains "$REPO_ROOT/.gitignore" "/skills/executing-plans"
}

test_repo_exposes_only_selected_skills() {
  local selected
  for selected in brainstorming writing-plans executing-plans harness-init frontend-slides-2.0.0 grill-with-docs; do
    assert_exists "$REPO_ROOT/skills/$selected/SKILL.md"
  done
  assert_real_directory "$REPO_ROOT/skills/brainstorming"
  assert_real_directory "$REPO_ROOT/skills/writing-plans"
  assert_real_directory "$REPO_ROOT/skills/executing-plans"
  assert_not_exists "$REPO_ROOT/superpowers"
  assert_not_exists "$REPO_ROOT/.gitmodules"
  local retired
  for retired in "${RETIRED_SKILLS[@]}"; do
    assert_not_exists "$REPO_ROOT/skills/$retired"
  done
  assert_not_exists "$REPO_ROOT/CLAUDE.md"
  assert_not_exists "$REPO_ROOT/CLAUDE.md.v1"
  assert_file_not_contains "$REPO_ROOT/AGENTS.md" "superman"
  assert_file_not_contains "$REPO_ROOT/AGENTS.md" "humanize"
  assert_file_not_contains "$REPO_ROOT/AGENTS.md" "using-superpowers"
  assert_file_not_contains "$REPO_ROOT/AGENTS.md" "harness:doc-health"
  assert_file_not_contains "$REPO_ROOT/skills/harness-init/SKILL.md" "harness:doc-health"
  assert_file_not_contains "$REPO_ROOT/skills/harness-init/SKILL.md" "local hooks"
  assert_file_not_contains "$REPO_ROOT/harness-bootstrap/skeleton/AGENTS.md" "harness:doc-health"
  assert_file_not_contains "$REPO_ROOT/harness-bootstrap/skeleton/MEMORY.md" "harness:doc-health"
}

test_powershell_script_exists() {
  assert_exists "$REPO_ROOT/sync-agent-links.ps1"
}

run_selected_tests() {
  local tests=(
    test_sync_links_local_skills_to_all_agents
    test_local_skills_are_self_contained
    test_missing_local_skill_fails_before_target_mutation
    test_invalid_local_skill_name_fails_before_target_mutation
    test_sync_removes_only_managed_retired_assets_and_humanize_hooks
    test_rerun_is_idempotent_when_links_are_correct
    test_codex_config_is_not_overwritten_by_default
    test_codex_config_can_be_copied_with_explicit_flag
    test_superpowers_environment_is_ignored
    test_pi_coding_agent_dir_override
    test_dry_run_does_not_relink_retired_skills
    test_kimi_code_home_override
    test_repo_ignore_rules_track_local_skills
    test_repo_exposes_only_selected_skills
    test_powershell_script_exists
  )

  if [[ -n "${TEST_FILTER:-}" ]]; then
    "${TEST_FILTER}"
    return
  fi

  local test_name
  for test_name in "${tests[@]}"; do
    "$test_name"
  done
}

run_selected_tests
printf 'PASS: sync-agent-links regression checks\n'
