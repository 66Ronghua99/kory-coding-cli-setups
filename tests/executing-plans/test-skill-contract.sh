#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SKILL="$REPO_ROOT/skills/executing-plans/SKILL.md"
PROMPT="$REPO_ROOT/skills/executing-plans/codex-review-prompt.md"
WRITING_PLANS="$REPO_ROOT/skills/writing-plans/SKILL.md"
PLAN_TEMPLATE="$REPO_ROOT/docs/superpowers/templates/PLAN_TEMPLATE.md"
AGENTS="$REPO_ROOT/AGENTS.md"
BASH_RUNNER="$REPO_ROOT/skills/executing-plans/scripts/run-codex-review.sh"
POWERSHELL_RUNNER="$REPO_ROOT/skills/executing-plans/scripts/run-codex-review.ps1"

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_file() {
  [[ -f "$1" ]] || fail "Expected file: $1"
}

assert_contains() {
  local path="$1"
  local expected="$2"
  grep -Fq -- "$expected" "$path" || fail "Expected $path to contain: $expected"
}

assert_not_contains() {
  local path="$1"
  local unexpected="$2"
  if grep -Fq -- "$unexpected" "$path"; then
    fail "Expected $path not to contain: $unexpected"
  fi
}

assert_file "$SKILL"
assert_file "$PROMPT"
assert_contains "$SKILL" 'name: executing-plans'
assert_contains "$SKILL" 'only when the user explicitly invokes'
assert_contains "$SKILL" 'The plan path is mandatory'
assert_contains "$SKILL" '`--no-codex-review`'
assert_contains "$SKILL" '**Execution:** [ ] complete'
assert_contains "$SKILL" '**Codex verification:** PENDING'
assert_contains "$SKILL" 'P0 and P1 block completion'
assert_contains "$SKILL" 'P2 does not block completion'
assert_contains "$SKILL" 'Never install or depend on hooks'
assert_not_contains "$SKILL" 'git commit '
assert_not_contains "$SKILL" 'git add '

assert_contains "$PROMPT" 'TASK_VERDICTS:'
assert_contains "$PROMPT" 'FINDINGS:'
assert_contains "$PROMPT" 'P2_NOTES:'
assert_contains "$PROMPT" 'VERDICT: PASS'
assert_contains "$PROMPT" 'VERDICT: BLOCKED'
assert_contains "$PROMPT" 'Do not edit the plan or working tree.'

for path in "$WRITING_PLANS" "$PLAN_TEMPLATE"; do
  assert_contains "$path" '**Execution:** [ ] complete'
  assert_contains "$path" '**Codex verification:** PENDING'
done
assert_contains "$WRITING_PLANS" 'Do not automatically invoke `executing-plans`.'
assert_contains "$AGENTS" '仅在用户显式调用时执行指定 plan：`executing-plans`'

if [[ -d "$REPO_ROOT/skills/executing-plans/hooks" ]]; then
  fail "executing-plans must not contain a hooks directory"
fi

if [[ -f "$BASH_RUNNER" ]]; then
  assert_contains "$BASH_RUNNER" 'gpt-5.6-sol'
  assert_contains "$BASH_RUNNER" 'gpt-5.5'
  assert_contains "$BASH_RUNNER" 'model_reasoning_effort="high"'
fi
if [[ -f "$POWERSHELL_RUNNER" ]]; then
  assert_contains "$POWERSHELL_RUNNER" 'gpt-5.6-sol'
  assert_contains "$POWERSHELL_RUNNER" 'gpt-5.5'
  assert_contains "$POWERSHELL_RUNNER" 'model_reasoning_effort="high"'
fi

for token in \
  'gpt-5.6-sol' \
  'gpt-5.5' \
  'model_reasoning_effort="high"' \
  'EXECUTING_PLANS_REVIEW_STATUS=' \
  'malformed-output' \
  'codex-cli-unavailable'; do
  assert_contains "$BASH_RUNNER" "$token"
  assert_contains "$POWERSHELL_RUNNER" "$token"
done

printf 'PASS: executing-plans static contract\n'
