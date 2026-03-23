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
  grep -Fq "$expected" "$path" || fail "Expected $path to contain: $expected"
}

assert_symlink_target() {
  local path="$1"
  local expected="$2"
  [[ -L "$path" ]] || fail "Expected symlink: $path"
  local actual
  actual="$(readlink "$path")"
  [[ "$actual" == "$expected" ]] || fail "Expected $path -> $expected, got $actual"
}

make_superpowers_remote() {
  local remote_root="$1"
  local worktree="$remote_root/work"
  local bare="$remote_root/remote.git"

  mkdir -p "$worktree/skills/using-superpowers"
  cat > "$worktree/skills/using-superpowers/SKILL.md" <<'EOF'
---
name: using-superpowers
description: test fixture
---

# Fixture
EOF
  (
    cd "$worktree"
    git init >/dev/null
    git config user.name "Test"
    git config user.email "test@example.com"
    git add skills/using-superpowers/SKILL.md
    git commit -m "init" >/dev/null
    git branch -M main
    git init --bare "$bare" >/dev/null
    git remote add origin "$bare"
    git push -u origin main >/dev/null
  )
  git -C "$bare" symbolic-ref HEAD refs/heads/main >/dev/null

  printf '%s\n' "$bare"
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
  local remote="$3"
  shift 3

  HOME="$home_dir" \
  SUPERPOWERS_REMOTE_URL="$remote" \
  bash "$source/sync-agent-links.sh" "$@"
}

test_bootstraps_superpowers_and_syncs_downstream_skills() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote
  remote="$(make_superpowers_remote "$tempdir/superpowers-remote")"
  make_fake_source "$source"
  mkdir -p "$home_dir"

  run_sync "$source" "$home_dir" "$remote"

  assert_exists "$source/superpowers/.git"
  assert_symlink_target "$source/skills/superpowers" "$source/superpowers/skills"
  assert_symlink_target "$home_dir/.claude/skills" "$source/skills"
  assert_symlink_target "$home_dir/.gemini/skills" "$source/skills"
  assert_symlink_target "$home_dir/.copilot/skills" "$source/skills"
  assert_symlink_target "$home_dir/.codex/skills/skills" "$source/skills"
}

test_update_mode_fast_forwards_superpowers_checkout() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote_root="$tempdir/superpowers-remote"
  local remote
  remote="$(make_superpowers_remote "$remote_root")"
  make_fake_source "$source"
  mkdir -p "$home_dir"

  run_sync "$source" "$home_dir" "$remote"

  cat > "$remote_root/work/skills/using-superpowers/UPDATED.md" <<'EOF'
updated
EOF
  (
    cd "$remote_root/work"
    git add skills/using-superpowers/UPDATED.md
    git commit -m "update" >/dev/null
    git push >/dev/null
  )

  run_sync "$source" "$home_dir" "$remote" --update-superpowers

  assert_exists "$source/superpowers/skills/using-superpowers/UPDATED.md"
}

test_conflicting_targets_are_backed_up() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote
  remote="$(make_superpowers_remote "$tempdir/superpowers-remote")"
  make_fake_source "$source"
  mkdir -p "$home_dir/.claude"
  printf 'old-claude\n' > "$home_dir/.claude/CLAUDE.md"

  run_sync "$source" "$home_dir" "$remote"

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
  local remote
  remote="$(make_superpowers_remote "$tempdir/superpowers-remote")"
  make_fake_source "$source"
  mkdir -p "$home_dir"

  run_sync "$source" "$home_dir" "$remote"
  run_sync "$source" "$home_dir" "$remote"

  assert_not_exists "$home_dir/.coding-cli-sync-backups"
}

test_missing_git_fails_when_superpowers_checkout_is_missing() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote
  remote="$(make_superpowers_remote "$tempdir/superpowers-remote")"
  make_fake_source "$source"
  mkdir -p "$home_dir" "$tempdir/bin"

  cat > "$tempdir/bin/git" <<'EOF'
#!/usr/bin/env bash
echo "git missing for test" >&2
exit 127
EOF
  chmod +x "$tempdir/bin/git"

  if HOME="$home_dir" SUPERPOWERS_REMOTE_URL="$remote" PATH="$tempdir/bin:/usr/bin:/bin" bash "$source/sync-agent-links.sh" >/tmp/test-sync-agent-links.out 2>/tmp/test-sync-agent-links.err; then
    fail "Expected sync to fail when git is unavailable"
  fi
}

test_non_git_superpowers_path_fails() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote
  remote="$(make_superpowers_remote "$tempdir/superpowers-remote")"
  make_fake_source "$source"
  mkdir -p "$home_dir" "$source/superpowers"
  printf 'not-a-git-repo\n' > "$source/superpowers/README.txt"

  if run_sync "$source" "$home_dir" "$remote"; then
    fail "Expected sync to fail when superpowers path is not a git repository"
  fi
}

test_empty_superpowers_directory_bootstraps_successfully() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote
  remote="$(make_superpowers_remote "$tempdir/superpowers-remote")"
  make_fake_source "$source"
  mkdir -p "$home_dir" "$source/superpowers"

  run_sync "$source" "$home_dir" "$remote"

  assert_exists "$source/superpowers/.git"
  assert_symlink_target "$source/skills/superpowers" "$source/superpowers/skills"
}

test_dirty_checkout_blocks_update_mode() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote_root="$tempdir/superpowers-remote"
  local remote
  remote="$(make_superpowers_remote "$remote_root")"
  make_fake_source "$source"
  mkdir -p "$home_dir"

  run_sync "$source" "$home_dir" "$remote"

  printf 'dirty\n' > "$source/superpowers/skills/using-superpowers/DIRTY.md"

  if run_sync "$source" "$home_dir" "$remote" --update-superpowers; then
    fail "Expected update mode to fail for dirty superpowers checkout"
  fi
}

test_non_fast_forward_update_fails() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote_root="$tempdir/superpowers-remote"
  local remote
  remote="$(make_superpowers_remote "$remote_root")"
  make_fake_source "$source"
  mkdir -p "$home_dir"

  run_sync "$source" "$home_dir" "$remote"

  (
    cd "$source/superpowers"
    git config user.name "Local Test"
    git config user.email "local@example.com"
    printf 'local\n' > LOCAL_ONLY.md
    git add LOCAL_ONLY.md
    git commit -m "local" >/dev/null
  )

  cat > "$remote_root/work/skills/using-superpowers/REMOTE_ONLY.md" <<'EOF'
remote
EOF
  (
    cd "$remote_root/work"
    git add skills/using-superpowers/REMOTE_ONLY.md
    git commit -m "remote" >/dev/null
    git push >/dev/null
  )

  if run_sync "$source" "$home_dir" "$remote" --update-superpowers; then
    fail "Expected update mode to fail when fast-forward is impossible"
  fi
}

test_powershell_script_exists() {
  assert_exists "$REPO_ROOT/sync-agent-links.ps1"
}

run_selected_tests() {
  local tests=(
    test_bootstraps_superpowers_and_syncs_downstream_skills
    test_update_mode_fast_forwards_superpowers_checkout
    test_conflicting_targets_are_backed_up
    test_rerun_is_idempotent_when_links_are_correct
    test_missing_git_fails_when_superpowers_checkout_is_missing
    test_non_git_superpowers_path_fails
    test_empty_superpowers_directory_bootstraps_successfully
    test_dirty_checkout_blocks_update_mode
    test_non_fast_forward_update_fails
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
