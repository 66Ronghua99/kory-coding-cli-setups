#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
CURATED_SKILLS=(
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

assert_file_not_contains() {
  local path="$1"
  local unexpected="$2"
  ! grep -Fq -- "$unexpected" "$path" || fail "Expected $path not to contain: $unexpected"
}

assert_symlink_target() {
  local path="$1"
  local expected="$2"
  [[ -L "$path" ]] || fail "Expected symlink: $path"
  local actual
  actual="$(readlink "$path")"
  [[ "$actual" == "$expected" ]] || fail "Expected $path -> $expected, got $actual"
}

assert_regular_file() {
  local path="$1"
  [[ -f "$path" && ! -L "$path" ]] || fail "Expected regular file: $path"
}

assert_skill_version() {
  local path="$1"
  local expected="$2"
  assert_file_contains "$path" "version: $expected"
}

make_superpowers_remote() {
  local remote_root="$1"
  local version="$2"
  local bare_repo="$remote_root/superpowers-remote.git"
  local work_repo="$remote_root/work"

  git init --bare "$bare_repo" >/dev/null
  git clone "$bare_repo" "$work_repo" >/dev/null 2>&1
  (
    cd "$work_repo"
    git config user.name "Test"
    git config user.email "test@example.com"
    mkdir -p skills
    local skill
    for skill in "${CURATED_SKILLS[@]}"; do
      mkdir -p "skills/$skill"
      cat > "skills/$skill/SKILL.md" <<EOF
---
name: $skill
description: test fixture
version: $version
---
EOF
    done
    cat >> "skills/brainstorming/SKILL.md" <<'EOF'

6. **Write design doc** — save to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` and commit

> "Spec written and committed to `<path>`."
EOF
    cat >> "skills/writing-plans/SKILL.md" <<'EOF'

**Save plans to:** `docs/superpowers/plans/YYYY-MM-DD-<feature-name>.md`

```bash
git add tests/path/test.py src/path/file.py docs/superpowers/plans/example.md
git commit -m "feat: add specific feature"
```
EOF
    printf 'fixture %s\n' "$version" > README.md
    git add README.md skills
    git commit -m "init $version" >/dev/null
    git branch -M main >/dev/null
    git push origin main >/dev/null
  )
}

make_humanize_remote() {
  local remote_root="$1"
  local version="$2"
  local bare_repo="$remote_root/humanize-remote.git"
  local work_repo="$remote_root/humanize-work"

  git init --bare "$bare_repo" >/dev/null
  git clone "$bare_repo" "$work_repo" >/dev/null 2>&1
  (
    cd "$work_repo"
    git config user.name "Test"
    git config user.email "test@example.com"
    mkdir -p scripts
    cat > scripts/install-codex-hooks.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

require_codex_hooks_support() {
    if ! codex features list 2>/dev/null | grep -qE '^codex_hooks[[:space:]]'; then
        echo "unsupported"
    fi
}
EOF
    cat > scripts/install-skill.sh <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "$0")" && pwd)"
if grep -Fq "grep -qE '^codex_hooks" "$script_dir/install-codex-hooks.sh"; then
  printf 'unpatched codex_hooks probe\n' >&2
  exit 1
fi

target="kimi"
kimi_skills_dir="${HOME}/.config/agents/skills"
codex_skills_dir="${HOME}/.codex/skills"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) target="$2"; shift 2 ;;
    --kimi-skills-dir) kimi_skills_dir="$2"; shift 2 ;;
    --codex-skills-dir) codex_skills_dir="$2"; shift 2 ;;
    *) shift ;;
  esac
done

mkdir -p "$HOME/.codex"
cat > "$HOME/.codex/hooks.json" <<'JSON'
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "humanize/hooks/loop-codex-stop-hook.sh"
          }
        ]
      }
    ]
  },
  "description": "Humanize Codex Hooks"
}
JSON

if [[ "$target" == "kimi" || "$target" == "both" ]]; then
  mkdir -p "$kimi_skills_dir/humanize/hooks"
  printf 'kimi humanize hook\n' > "$kimi_skills_dir/humanize/hooks/loop-kimi-stop-hook.sh"
  printf 'kimi humanize skill\n' > "$kimi_skills_dir/humanize/SKILL.md"
fi
if [[ "$target" == "codex" || "$target" == "both" ]]; then
  mkdir -p "$codex_skills_dir/humanize/hooks"
  printf 'codex humanize hook\n' > "$codex_skills_dir/humanize/hooks/loop-codex-stop-hook.sh"
fi

printf 'install-skill --target %s HOME=%s\n' "$target" "${HOME:-}" >> "${HUMANIZE_INSTALL_LOG:?}"
EOF
    chmod +x scripts/install-skill.sh scripts/install-codex-hooks.sh
    printf 'humanize %s\n' "$version" > VERSION
    git add VERSION scripts/install-skill.sh scripts/install-codex-hooks.sh
    git commit -m "init humanize $version" >/dev/null
    git branch -M main >/dev/null
    git push origin main >/dev/null
  )
}

update_superpowers_remote() {
  local remote_root="$1"
  local version="$2"
  local work_repo="$remote_root/update-work"
  local bare_repo="$remote_root/superpowers-remote.git"

  git clone "$bare_repo" "$work_repo" >/dev/null 2>&1
  (
    cd "$work_repo"
    git checkout main >/dev/null 2>&1
    git config user.name "Test"
    git config user.email "test@example.com"
    local skill
    for skill in "${CURATED_SKILLS[@]}"; do
      cat > "skills/$skill/SKILL.md" <<EOF
---
name: $skill
description: test fixture
version: $version
---
EOF
    done
    printf 'fixture %s\n' "$version" > README.md
    git add README.md skills
    git commit -m "update $version" >/dev/null
    git push origin main >/dev/null
  )
}

update_humanize_remote() {
  local remote_root="$1"
  local version="$2"
  local work_repo="$remote_root/humanize-update-work"
  local bare_repo="$remote_root/humanize-remote.git"

  git clone "$bare_repo" "$work_repo" >/dev/null 2>&1
  (
    cd "$work_repo"
    git checkout main >/dev/null 2>&1
    git config user.name "Test"
    git config user.email "test@example.com"
    printf 'humanize %s\n' "$version" > VERSION
    git add VERSION
    git commit -m "update humanize $version" >/dev/null
    git push origin main >/dev/null
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
  local remote_url="$3"
  local branch="$4"
  local remote_root
  remote_root="$(dirname "$remote_url")"
  shift 2

  HOME="$home_dir" \
    SUPERPOWERS_REMOTE_URL="$remote_url" \
    SUPERPOWERS_BRANCH="$branch" \
    HUMANIZE_REMOTE_URL="${HUMANIZE_TEST_REMOTE_URL:-$remote_root/humanize-remote.git}" \
    HUMANIZE_BRANCH="${HUMANIZE_TEST_BRANCH:-main}" \
    HUMANIZE_SYNC="${HUMANIZE_TEST_SYNC:-1}" \
    HUMANIZE_INSTALL_LOG="${HUMANIZE_TEST_INSTALL_LOG:-$home_dir/humanize-install.log}" \
    bash "$source/sync-agent-links.sh" "${@:3}"
}

assert_curated_skill_links() {
  local source="$1"
  local skill
  for skill in "${CURATED_SKILLS[@]}"; do
    assert_symlink_target "$source/skills/$skill" "$source/superpowers/skills/$skill"
  done
}

test_sync_clones_and_exports_curated_skills() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote_root="$tempdir/remote"
  local remote_url="$remote_root/superpowers-remote.git"
  make_fake_source "$source"
  make_superpowers_remote "$remote_root" "v1"
  make_humanize_remote "$remote_root" "v1"
  mkdir -p "$home_dir"

  run_sync "$source" "$home_dir" "$remote_url" "main"

  assert_exists "$source/superpowers/.git"
  assert_curated_skill_links "$source"
  assert_not_exists "$source/skills/superpowers"
  assert_symlink_target "$home_dir/.claude/skills" "$source/skills"
  assert_symlink_target "$home_dir/.gemini/skills" "$source/skills"
  assert_symlink_target "$home_dir/.copilot/skills" "$source/skills"
  assert_exists "$home_dir/.codex/skills"
  assert_symlink_target "$home_dir/.codex/skills/using-superpowers" "$source/skills/using-superpowers"
  assert_skill_version "$home_dir/.codex/skills/using-superpowers/SKILL.md" "v1"
  assert_not_exists "$home_dir/.codex/skills/skills"
  assert_exists "$home_dir/.codex/skills/sample-skill/SKILL.md"
  assert_symlink_target "$home_dir/.kimi-code/AGENTS.md" "$source/AGENTS.md"
  assert_symlink_target "$home_dir/.kimi-code/skills" "$source/skills"
}

test_sync_patches_superpowers_local_only_policy() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote_root="$tempdir/remote"
  local remote_url="$remote_root/superpowers-remote.git"
  make_fake_source "$source"
  make_superpowers_remote "$remote_root" "v1"
  make_humanize_remote "$remote_root" "v1"
  mkdir -p "$home_dir"

  run_sync "$source" "$home_dir" "$remote_url" "main"

  assert_file_not_contains "$source/skills/brainstorming/SKILL.md" "and commit"
  assert_file_contains "$source/skills/brainstorming/SKILL.md" 'save locally to `docs/superpowers/specs/YYYY-MM-DD-<topic>-design.md` without staging or committing it'
  assert_file_not_contains "$source/skills/brainstorming/SKILL.md" "Spec written and committed"
  assert_file_contains "$source/skills/brainstorming/SKILL.md" 'Spec written locally to `<path>`'
  assert_file_not_contains "$source/skills/writing-plans/SKILL.md" "docs/superpowers/plans/example.md"
  assert_file_contains "$source/skills/writing-plans/SKILL.md" 'Do not stage or commit `docs/superpowers/`, `PROGRESS.md`, `MEMORY.md`, `NEXT_STEP.md`, or `artifacts/`.'
}

test_sync_pulls_latest_superpowers_content() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote_root="$tempdir/remote"
  local remote_url="$remote_root/superpowers-remote.git"
  make_fake_source "$source"
  make_superpowers_remote "$remote_root" "v1"
  make_humanize_remote "$remote_root" "v1"
  mkdir -p "$home_dir"

  run_sync "$source" "$home_dir" "$remote_url" "main"
  update_superpowers_remote "$remote_root" "v2"
  run_sync "$source" "$home_dir" "$remote_url" "main"

  assert_skill_version "$source/superpowers/skills/using-superpowers/SKILL.md" "v2"
  assert_skill_version "$home_dir/.claude/skills/using-superpowers/SKILL.md" "v2"
}

test_conflicting_targets_are_backed_up() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote_root="$tempdir/remote"
  local remote_url="$remote_root/superpowers-remote.git"
  make_fake_source "$source"
  make_superpowers_remote "$remote_root" "v1"
  make_humanize_remote "$remote_root" "v1"
  mkdir -p "$home_dir/.claude"
  printf 'old-claude\n' > "$home_dir/.claude/CLAUDE.md"

  run_sync "$source" "$home_dir" "$remote_url" "main"

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
  local remote_root="$tempdir/remote"
  local remote_url="$remote_root/superpowers-remote.git"
  make_fake_source "$source"
  make_superpowers_remote "$remote_root" "v1"
  make_humanize_remote "$remote_root" "v1"
  mkdir -p "$home_dir"

  run_sync "$source" "$home_dir" "$remote_url" "main"
  run_sync "$source" "$home_dir" "$remote_url" "main"

  assert_not_exists "$home_dir/.coding-cli-sync-backups"
}

test_codex_config_is_not_overwritten_by_default() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote_root="$tempdir/remote"
  local remote_url="$remote_root/superpowers-remote.git"
  make_fake_source "$source"
  make_superpowers_remote "$remote_root" "v1"
  make_humanize_remote "$remote_root" "v1"
  mkdir -p "$home_dir/.codex"
  printf 'local-config\n' > "$home_dir/.codex/config.toml"

  run_sync "$source" "$home_dir" "$remote_url" "main"

  assert_regular_file "$home_dir/.codex/config.toml"
  assert_file_contains "$home_dir/.codex/config.toml" "local-config"
  assert_file_not_contains "$home_dir/.codex/config.toml" 'model = "gpt-5.4"'
}

test_codex_config_symlink_is_converted_to_regular_file() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote_root="$tempdir/remote"
  local remote_url="$remote_root/superpowers-remote.git"
  make_fake_source "$source"
  make_superpowers_remote "$remote_root" "v1"
  make_humanize_remote "$remote_root" "v1"
  mkdir -p "$home_dir/.codex"
  ln -s "$source/.codex/config.toml" "$home_dir/.codex/config.toml"

  run_sync "$source" "$home_dir" "$remote_url" "main"

  assert_regular_file "$home_dir/.codex/config.toml"
  assert_file_contains "$home_dir/.codex/config.toml" 'model = "gpt-5.4"'
}

test_codex_config_can_be_copied_with_explicit_flag() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote_root="$tempdir/remote"
  local remote_url="$remote_root/superpowers-remote.git"
  make_fake_source "$source"
  make_superpowers_remote "$remote_root" "v1"
  make_humanize_remote "$remote_root" "v1"
  mkdir -p "$home_dir/.codex"
  printf 'local-config\n' > "$home_dir/.codex/config.toml"

  run_sync "$source" "$home_dir" "$remote_url" "main" --sync-codex-config

  assert_regular_file "$home_dir/.codex/config.toml"
  assert_file_contains "$home_dir/.codex/config.toml" 'model = "gpt-5.4"'
  assert_file_not_contains "$home_dir/.codex/config.toml" "local-config"
}

test_existing_non_git_superpowers_path_fails() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote_root="$tempdir/remote"
  local remote_url="$remote_root/superpowers-remote.git"
  make_fake_source "$source"
  make_superpowers_remote "$remote_root" "v1"
  make_humanize_remote "$remote_root" "v1"
  mkdir -p "$home_dir" "$source/superpowers"
  printf 'not-a-git-repo\n' > "$source/superpowers/README.txt"

  if run_sync "$source" "$home_dir" "$remote_url" "main" >/tmp/test-sync-agent-links.out 2>/tmp/test-sync-agent-links.err; then
    fail "Expected sync to fail when superpowers path is not a git repository"
  fi
  assert_file_contains /tmp/test-sync-agent-links.err "not a git repository"
}

test_legacy_namespace_is_replaced() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote_root="$tempdir/remote"
  local remote_url="$remote_root/superpowers-remote.git"
  make_fake_source "$source"
  make_superpowers_remote "$remote_root" "v1"
  make_humanize_remote "$remote_root" "v1"
  mkdir -p "$home_dir" "$source/skills"
  ln -s "$source/superpowers/skills" "$source/skills/superpowers"

  run_sync "$source" "$home_dir" "$remote_url" "main"

  assert_not_exists "$source/skills/superpowers"
  assert_curated_skill_links "$source"
}

test_deprecated_codex_skill_links_are_removed() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote_root="$tempdir/remote"
  local remote_url="$remote_root/superpowers-remote.git"
  make_fake_source "$source"
  make_superpowers_remote "$remote_root" "v1"
  make_humanize_remote "$remote_root" "v1"
  mkdir -p "$home_dir/.codex/skills"

  local skill
  for skill in "${DEPRECATED_CODEX_SKILLS[@]}"; do
    ln -s "$source/skills/$skill" "$home_dir/.codex/skills/$skill"
  done

  run_sync "$source" "$home_dir" "$remote_url" "main"

  for skill in "${DEPRECATED_CODEX_SKILLS[@]}"; do
    assert_not_exists "$home_dir/.codex/skills/$skill"
  done
}

test_invalid_remote_fails_cleanly() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local invalid_remote="$tempdir/does-not-exist.git"
  make_fake_source "$source"
  make_humanize_remote "$tempdir/remote" "v1"
  mkdir -p "$home_dir"

  if run_sync "$source" "$home_dir" "$invalid_remote" "main" >/tmp/test-sync-agent-links.out 2>/tmp/test-sync-agent-links.err; then
    fail "Expected sync to fail when superpowers remote is invalid"
  fi
}

test_powershell_script_exists() {
  assert_exists "$REPO_ROOT/sync-agent-links.ps1"
}

test_humanize_checkout_and_generated_skills_are_gitignored() {
  assert_file_contains "$REPO_ROOT/.gitignore" "/humanize/"
  assert_file_contains "$REPO_ROOT/.gitignore" "/skills/humanize*"

  local skill
  for skill in humanize humanize-gen-plan humanize-refine-plan humanize-rlcr; do
    git -C "$REPO_ROOT" check-ignore -q "skills/$skill" || fail "Expected skills/$skill to be gitignored"
  done
}

test_sync_installs_humanize_rlcr_for_kimi_and_codex() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote_root="$tempdir/remote"
  local remote_url="$remote_root/superpowers-remote.git"
  local install_log="$tempdir/humanize-install.log"
  make_fake_source "$source"
  make_superpowers_remote "$remote_root" "v1"
  make_humanize_remote "$remote_root" "v1"
  mkdir -p "$home_dir"

  HUMANIZE_TEST_INSTALL_LOG="$install_log" run_sync "$source" "$home_dir" "$remote_url" "main"

  assert_exists "$source/humanize/.git"
  assert_file_contains "$source/humanize/VERSION" "humanize v1"
  assert_file_contains "$install_log" "install-skill --target both"
  assert_file_contains "$install_log" "HOME=$home_dir"
  assert_file_contains "$home_dir/.codex/hooks.json" '"hooks"'
  assert_file_not_contains "$home_dir/.codex/hooks.json" '"description"'
  assert_exists "$source/skills/humanize/SKILL.md"
  assert_exists "$source/skills/humanize/hooks/loop-kimi-stop-hook.sh"
  assert_symlink_target "$home_dir/.kimi-code/skills" "$source/skills"
  assert_exists "$home_dir/.kimi-code/skills/humanize/SKILL.md"
  assert_exists "$home_dir/.kimi-code/skills/humanize/hooks/loop-kimi-stop-hook.sh"
  assert_exists "$home_dir/.codex/skills/humanize/SKILL.md"
  assert_exists "$home_dir/.kimi-code/config.toml"
  assert_file_contains "$home_dir/.kimi-code/config.toml" "event = \"Stop\""
  assert_file_contains "$home_dir/.kimi-code/config.toml" "$source/skills/humanize/hooks/loop-kimi-stop-hook.sh"
}

test_sync_updates_humanize_checkout_on_rerun() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote_root="$tempdir/remote"
  local remote_url="$remote_root/superpowers-remote.git"
  local install_log="$tempdir/humanize-install.log"
  make_fake_source "$source"
  make_superpowers_remote "$remote_root" "v1"
  make_humanize_remote "$remote_root" "v1"
  mkdir -p "$home_dir"

  HUMANIZE_TEST_INSTALL_LOG="$install_log" run_sync "$source" "$home_dir" "$remote_url" "main"
  update_humanize_remote "$remote_root" "v2"
  HUMANIZE_TEST_INSTALL_LOG="$install_log" run_sync "$source" "$home_dir" "$remote_url" "main"

  assert_file_contains "$source/humanize/VERSION" "humanize v2"
  [[ "$(grep -c 'install-skill --target both' "$install_log")" == "2" ]] || fail "Expected Humanize installer to run on each sync"
}

test_kimi_code_home_override() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local kimi_home="$tempdir/kimi-home"
  local remote_root="$tempdir/remote"
  local remote_url="$remote_root/superpowers-remote.git"
  make_fake_source "$source"
  make_superpowers_remote "$remote_root" "v1"
  make_humanize_remote "$remote_root" "v1"
  mkdir -p "$home_dir"

  HOME="$home_dir" KIMI_CODE_HOME="$kimi_home" \
    SUPERPOWERS_REMOTE_URL="$remote_url" \
    SUPERPOWERS_BRANCH="main" \
    HUMANIZE_REMOTE_URL="${HUMANIZE_TEST_REMOTE_URL:-$remote_root/humanize-remote.git}" \
    HUMANIZE_BRANCH="${HUMANIZE_TEST_BRANCH:-main}" \
    HUMANIZE_SYNC="${HUMANIZE_TEST_SYNC:-1}" \
    HUMANIZE_INSTALL_LOG="${HUMANIZE_TEST_INSTALL_LOG:-$home_dir/humanize-install.log}" \
    bash "$source/sync-agent-links.sh"

  assert_symlink_target "$kimi_home/AGENTS.md" "$source/AGENTS.md"
  assert_symlink_target "$kimi_home/skills" "$source/skills"
  assert_not_exists "$home_dir/.kimi-code"
}

test_humanize_sync_can_be_disabled() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote_root="$tempdir/remote"
  local remote_url="$remote_root/superpowers-remote.git"
  local install_log="$tempdir/humanize-install.log"
  make_fake_source "$source"
  make_superpowers_remote "$remote_root" "v1"
  make_humanize_remote "$remote_root" "v1"
  mkdir -p "$home_dir"

  HUMANIZE_TEST_SYNC=0 HUMANIZE_TEST_INSTALL_LOG="$install_log" run_sync "$source" "$home_dir" "$remote_url" "main"

  assert_not_exists "$source/humanize"
  assert_not_exists "$install_log"
}

test_dry_run_allows_missing_humanize_checkout() {
  local tempdir
  tempdir="$(mktemp -d)"
  local source="$tempdir/source"
  local home_dir="$tempdir/home"
  local remote_root="$tempdir/remote"
  local remote_url="$remote_root/superpowers-remote.git"
  make_fake_source "$source"
  make_superpowers_remote "$remote_root" "v1"
  make_humanize_remote "$remote_root" "v1"
  mkdir -p "$home_dir"

  HUMANIZE_TEST_SYNC=0 run_sync "$source" "$home_dir" "$remote_url" "main"

  HUMANIZE_TEST_SYNC=1 run_sync "$source" "$home_dir" "$remote_url" "main" --dry-run >/tmp/test-sync-agent-links-dry-run.out

  assert_not_exists "$source/humanize"
  assert_file_contains /tmp/test-sync-agent-links-dry-run.out "[dry-run] git clone --branch main --single-branch $remote_root/humanize-remote.git $source/humanize"
  assert_file_contains /tmp/test-sync-agent-links-dry-run.out "[dry-run] $source/humanize/scripts/install-skill.sh --target both --kimi-skills-dir $source/skills --codex-skills-dir $source/skills"
}

run_selected_tests() {
  local tests=(
    test_sync_clones_and_exports_curated_skills
    test_sync_patches_superpowers_local_only_policy
    test_sync_pulls_latest_superpowers_content
    test_conflicting_targets_are_backed_up
    test_rerun_is_idempotent_when_links_are_correct
    test_codex_config_is_not_overwritten_by_default
    test_codex_config_symlink_is_converted_to_regular_file
    test_codex_config_can_be_copied_with_explicit_flag
    test_existing_non_git_superpowers_path_fails
    test_legacy_namespace_is_replaced
    test_deprecated_codex_skill_links_are_removed
    test_invalid_remote_fails_cleanly
    test_sync_installs_humanize_rlcr_for_kimi_and_codex
    test_sync_updates_humanize_checkout_on_rerun
    test_humanize_sync_can_be_disabled
    test_dry_run_allows_missing_humanize_checkout
    test_powershell_script_exists
    test_humanize_checkout_and_generated_skills_are_gitignored
    test_kimi_code_home_override
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
