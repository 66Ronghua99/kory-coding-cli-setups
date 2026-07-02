#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$TEST_DIR/../.." && pwd)"
PACK_ROOT="$REPO_ROOT/harness-bootstrap"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_ignored() {
  local target_dir="$1"
  local path="$2"

  git -C "$target_dir" check-ignore --no-index -q "$path" || fail "Expected $path to be gitignored"
}

assert_not_ignored() {
  local target_dir="$1"
  local path="$2"

  if git -C "$target_dir" check-ignore --no-index -q "$path"; then
    fail "Expected $path to remain trackable"
  fi
}

assert_file_contains() {
  local file_path="$1"
  local expected="$2"

  grep -Fqx "$expected" "$file_path" || fail "Expected $file_path to contain: $expected"
}

assert_not_tracked() {
  local target_dir="$1"
  local path="$2"

  if git -C "$target_dir" ls-files --error-unmatch "$path" >/dev/null 2>&1; then
    fail "Expected $path to be removed from git tracking"
  fi
}

assert_harness_gitignore_contract() {
  local target_dir="$1"

  assert_file_contains "$target_dir/.gitignore" "docs/superpowers/"
  assert_file_contains "$target_dir/.gitignore" "artifacts/"
  assert_file_contains "$target_dir/.gitignore" "/*.md"
  assert_file_contains "$target_dir/.gitignore" "!/AGENTS.md"
  assert_file_contains "$target_dir/.gitignore" "!/README.md"

  assert_ignored "$target_dir" "docs/superpowers/templates/SPEC_TEMPLATE.md"
  assert_ignored "$target_dir" "artifacts/verification.log"
  assert_ignored "$target_dir" "PROGRESS.md"
  assert_ignored "$target_dir" "MEMORY.md"
  assert_ignored "$target_dir" "NEXT_STEP.md"
  assert_not_ignored "$target_dir" "AGENTS.md"
  assert_not_ignored "$target_dir" "README.md"
}

test_greenfield_bootstrap_adds_harness_gitignore_entries() {
  local target_dir="$1/greenfield"
  mkdir -p "$target_dir"

  bash "$PACK_ROOT/scripts/bootstrap_greenfield.sh" "$target_dir" "$PACK_ROOT" >/dev/null

  git -C "$target_dir" init -q
  assert_harness_gitignore_contract "$target_dir"
}

test_migration_bootstrap_appends_harness_gitignore_entries() {
  local target_dir="$1/migration"
  mkdir -p "$target_dir"
  git -C "$target_dir" init -q
  printf '/build/\n' > "$target_dir/.gitignore"
  printf '{"scripts":{"test":"echo ok"}}\n' > "$target_dir/package.json"

  bash "$PACK_ROOT/scripts/bootstrap_migration.sh" "$target_dir" "$PACK_ROOT" >/dev/null

  assert_file_contains "$target_dir/.gitignore" "/build/"
  assert_harness_gitignore_contract "$target_dir"
}

test_migration_bootstrap_untracks_local_only_docs() {
  local target_dir="$1/migration-tracked"
  mkdir -p "$target_dir/docs/superpowers/specs" "$target_dir/artifacts"
  git -C "$target_dir" init -q
  printf '/build/\n' > "$target_dir/.gitignore"
  printf '{"scripts":{"test":"echo ok"}}\n' > "$target_dir/package.json"
  printf 'progress\n' > "$target_dir/PROGRESS.md"
  printf 'memory\n' > "$target_dir/MEMORY.md"
  printf 'next\n' > "$target_dir/NEXT_STEP.md"
  printf 'spec\n' > "$target_dir/docs/superpowers/specs/example.md"
  printf 'artifact\n' > "$target_dir/artifacts/verification.log"
  git -C "$target_dir" add -f PROGRESS.md MEMORY.md NEXT_STEP.md docs/superpowers/specs/example.md artifacts/verification.log

  bash "$PACK_ROOT/scripts/bootstrap_migration.sh" "$target_dir" "$PACK_ROOT" >/dev/null

  assert_not_tracked "$target_dir" "PROGRESS.md"
  assert_not_tracked "$target_dir" "MEMORY.md"
  assert_not_tracked "$target_dir" "NEXT_STEP.md"
  assert_not_tracked "$target_dir" "docs/superpowers/specs/example.md"
  assert_not_tracked "$target_dir" "artifacts/verification.log"
  assert_harness_gitignore_contract "$target_dir"
}

main() {
  local tmp_root
  tmp_root="$(mktemp -d)"
  trap "rm -rf '$tmp_root'" EXIT

  test_greenfield_bootstrap_adds_harness_gitignore_entries "$tmp_root"
  test_migration_bootstrap_appends_harness_gitignore_entries "$tmp_root"
  test_migration_bootstrap_untracks_local_only_docs "$tmp_root"

  echo "bootstrap-gitignore-tests-pass"
}

main "$@"
