#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

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

assert_file_contains() {
  local path="$1"
  local expected="$2"
  grep -Fq -- "$expected" "$path" || fail "Expected $path to contain: $expected"
}

assert_symlink_target() {
  local path="$1"
  local expected="$2"
  [[ -L "$path" ]] || fail "Expected symlink: $path"
  local actual
  actual="$(readlink "$path")"
  [[ "$actual" == "$expected" ]] || fail "Expected $path -> $expected, got $actual"
}

make_superpowers_checkout() {
  local source="$1"

  mkdir -p "$source/superpowers/skills/using-superpowers"
  cat > "$source/superpowers/skills/using-superpowers/SKILL.md" <<'EOF'
---
name: using-superpowers
description: test fixture
---
EOF
  (
    cd "$source/superpowers"
    git init >/dev/null
    git config user.name "Test"
    git config user.email "test@example.com"
    printf 'fixture\n' > README.md
    git add README.md
    git commit -m "init" >/dev/null
  )
}

make_fake_source() {
  local source="$1"
  mkdir -p "$source/.codex/agents" "$source/skills/sample-skill"
  cp "$REPO_ROOT/sync-agent-links.sh" "$source/sync-agent-links.sh"
  chmod +x "$source/sync-agent-links.sh"
  cat > "$source/CLAUDE.md" <<'EOF'
# CLAUDE
EOF
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
model = "gpt-5.4"
EOF
  cat > "$source/.codex/agents/explorer.toml" <<'EOF'
description = "explorer"
EOF
  cat > "$source/skills/sample-skill/SKILL.md" <<'EOF'
---
name: sample-skill
description: sample
---
EOF
}

run_sync() {
  local source="$1"
  local home_dir="$2"
  shift 2

  HOME="$home_dir" bash "$source/sync-agent-links.sh" "$@"
}

test_syncs_initialized_superpowers_checkout() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  make_fake_source "$source"
  make_superpowers_checkout "$source"
  mkdir -p "$home_dir"

  run_sync "$source" "$home_dir"

  assert_symlink_target "$source/skills/superpowers" "$source/superpowers/skills"
  assert_symlink_target "$home_dir/.claude/skills" "$source/skills"
  assert_symlink_target "$home_dir/.gemini/skills" "$source/skills"
  assert_symlink_target "$home_dir/.copilot/skills" "$source/skills"
  assert_symlink_target "$home_dir/.codex/skills/skills" "$source/skills"
  assert_exists "$home_dir/.codex/skills/skills/superpowers/using-superpowers/SKILL.md"
}

test_conflicting_targets_are_backed_up() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  make_fake_source "$source"
  make_superpowers_checkout "$source"
  mkdir -p "$home_dir/.claude"
  printf 'old-claude\n' > "$home_dir/.claude/CLAUDE.md"

  run_sync "$source" "$home_dir"

  assert_symlink_target "$home_dir/.claude/CLAUDE.md" "$source/CLAUDE.md"
  local backup_file
  backup_file="$(find "$home_dir/.coding-cli-sync-backups" -path '*/.claude/CLAUDE.md' -print -quit)"
  [[ -n "$backup_file" ]] || fail "Expected backup for conflicting .claude/CLAUDE.md"
  assert_file_contains "$backup_file" 'old-claude'
}

test_rerun_is_idempotent_when_links_are_correct() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  make_fake_source "$source"
  make_superpowers_checkout "$source"
  mkdir -p "$home_dir"

  run_sync "$source" "$home_dir"
  run_sync "$source" "$home_dir"

  assert_not_exists "$home_dir/.coding-cli-sync-backups"
}

test_missing_superpowers_checkout_fails() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  make_fake_source "$source"
  mkdir -p "$home_dir"

  if run_sync "$source" "$home_dir" >/tmp/test-sync-agent-links.out 2>/tmp/test-sync-agent-links.err; then
    fail "Expected sync to fail when superpowers checkout is missing"
  fi
  assert_file_contains /tmp/test-sync-agent-links.err "git submodule update --init --recursive"
}

test_non_git_superpowers_path_fails() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  make_fake_source "$source"
  mkdir -p "$home_dir" "$source/superpowers/skills"
  printf 'not-a-git-repo\n' > "$source/superpowers/README.txt"

  if run_sync "$source" "$home_dir"; then
    fail "Expected sync to fail when superpowers path is not a git repository"
  fi
}

test_update_flag_fails_with_actionable_message() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  make_fake_source "$source"
  make_superpowers_checkout "$source"
  mkdir -p "$home_dir"

  if run_sync "$source" "$home_dir" --update-superpowers >/tmp/test-sync-agent-links-update.out 2>/tmp/test-sync-agent-links-update.err; then
    fail "Expected legacy update flag to fail"
  fi
  assert_file_contains /tmp/test-sync-agent-links-update.err "git submodule update --remote superpowers"
}

test_powershell_script_exists() {
  assert_exists "$REPO_ROOT/sync-agent-links.ps1"
}

run_selected_tests() {
  local tests=(
    test_syncs_initialized_superpowers_checkout
    test_conflicting_targets_are_backed_up
    test_rerun_is_idempotent_when_links_are_correct
    test_missing_superpowers_checkout_fails
    test_non_git_superpowers_path_fails
    test_update_flag_fails_with_actionable_message
    test_powershell_script_exists
  )

  local test_name
  for test_name in "${tests[@]}"; do
    if [[ -n "${TEST_FILTER:-}" && "$test_name" != "$TEST_FILTER" ]]; then
      continue
    fi
    "$test_name"
  done
}

run_selected_tests

printf 'PASS: sync-agent-links regression checks\n'
