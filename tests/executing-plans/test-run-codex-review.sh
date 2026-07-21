#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
RUNNER="$REPO_ROOT/skills/executing-plans/scripts/run-codex-review.sh"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

fail() {
  printf 'FAIL: %s\n' "$*" >&2
  exit 1
}

assert_contains() {
  local path="$1"
  local expected="$2"
  grep -Fq -- "$expected" "$path" || fail "Expected $path to contain: $expected"
}

assert_exit() {
  local expected="$1"
  local actual="$2"
  [[ "$actual" -eq "$expected" ]] || fail "Expected exit $expected, got $actual"
}

PLAN="$TEMP_DIR/plan.md"
cat > "$PLAN" <<'PLAN'
### Task 1: Parser

**Execution:** [x] complete
**Codex verification:** PENDING

### Task 2: Sync

**Execution:** [x] complete
**Codex verification:** PENDING

~~~~markdown
### Task 99: Documentation example

**Execution:** [x] complete
**Codex verification:** PENDING
~~~~
PLAN

FAKE_CODEX="$TEMP_DIR/fake-codex"
cat > "$FAKE_CODEX" <<'FAKE'
#!/usr/bin/env bash
set -euo pipefail
count_file="$FAKE_CAPTURE_DIR/count"
count=0
[[ -f "$count_file" ]] && count="$(cat "$count_file")"
count=$((count + 1))
printf '%s' "$count" > "$count_file"
printf '%s\n' "$*" >> "$FAKE_CAPTURE_DIR/args"
cat > "$FAKE_CAPTURE_DIR/request.$count"

pass_output() {
  cat <<'OUT'
TASK_VERDICTS:
- Task 1: VERIFIED
- Task 2: VERIFIED

FINDINGS:
none

P2_NOTES:
none

VERDICT: PASS
OUT
}

case "$FAKE_SCENARIO" in
  pass)
    pass_output
    ;;
  blocked)
    cat <<'OUT'
TASK_VERDICTS:
- Task 1: VERIFIED
- Task 2: BLOCKED

FINDINGS:
- [P1] Task 2 — sync.sh:20 — required mapping is absent — add the mapping

P2_NOTES:
none

VERDICT: BLOCKED
OUT
    ;;
  p2)
    cat <<'OUT'
TASK_VERDICTS:
- Task 1: VERIFIED
- Task 2: VERIFIED

FINDINGS:
none

P2_NOTES:
- [P2] Task 1 — parser.test:10 — fixture name is unclear — rename it later

VERDICT: PASS
OUT
    ;;
  fallback)
    if [[ "$*" == *'gpt-5.6-sol'* ]]; then
      printf 'rate limit reached for model gpt-5.6-sol\n' >&2
      exit 1
    fi
    pass_output
    ;;
  malformed)
    printf 'VERDICT: PASS\n'
    ;;
  inconsistent)
    cat <<'OUT'
TASK_VERDICTS:
- Task 1: VERIFIED
- Task 2: BLOCKED

FINDINGS:
- [P1] Task 1 — parser.sh:20 — finding conflicts with task verdict — correct the verdict

P2_NOTES:
none

VERDICT: BLOCKED
OUT
    ;;
  *)
    printf 'unknown fake scenario: %s\n' "$FAKE_SCENARIO" >&2
    exit 9
    ;;
esac
FAKE
chmod +x "$FAKE_CODEX"

run_case() {
  local scenario="$1"
  local output="$2"
  rm -f "$TEMP_DIR/count" "$TEMP_DIR/args" "$TEMP_DIR"/request.*
  set +e
  printf '%s\n' 'goal: execute the parser and sync plan' 'self-check: focused verification passed' |
    FAKE_CAPTURE_DIR="$TEMP_DIR" FAKE_SCENARIO="$scenario" CODEX_BIN="$FAKE_CODEX" \
      bash "$RUNNER" --plan "$PLAN" >"$output" 2>&1
  CASE_EXIT=$?
  set -e
}

output="$TEMP_DIR/pass.out"
run_case pass "$output"
assert_exit 0 "$CASE_EXIT"
assert_contains "$output" 'EXECUTING_PLANS_REVIEW_STATUS=PASS MODEL=gpt-5.6-sol'
assert_contains "$TEMP_DIR/request.1" 'Expected task IDs: 1,2'
assert_contains "$TEMP_DIR/request.1" 'goal: execute the parser and sync plan'

output="$TEMP_DIR/blocked.out"
run_case blocked "$output"
assert_exit 1 "$CASE_EXIT"
assert_contains "$output" 'EXECUTING_PLANS_REVIEW_STATUS=BLOCKED MODEL=gpt-5.6-sol'

output="$TEMP_DIR/p2.out"
run_case p2 "$output"
assert_exit 0 "$CASE_EXIT"
assert_contains "$output" '[P2] Task 1'

output="$TEMP_DIR/fallback.out"
run_case fallback "$output"
assert_exit 0 "$CASE_EXIT"
assert_contains "$output" 'EXECUTING_PLANS_REVIEW_STATUS=PASS MODEL=gpt-5.5'
assert_contains "$TEMP_DIR/args" 'gpt-5.6-sol'
assert_contains "$TEMP_DIR/args" 'gpt-5.5'

for scenario in malformed inconsistent; do
  output="$TEMP_DIR/$scenario.out"
  run_case "$scenario" "$output"
  assert_exit 2 "$CASE_EXIT"
  assert_contains "$output" 'EXECUTING_PLANS_REVIEW_STATUS=SKIPPED MODEL=gpt-5.6-sol REASON=malformed-output'
  assert_contains "$TEMP_DIR/count" '2'
done

set +e
printf '%s\n' 'review context' | CODEX_BIN="$TEMP_DIR/missing-codex" \
  bash "$RUNNER" --plan "$PLAN" >"$TEMP_DIR/missing.out" 2>&1
missing_exit=$?
set -e
assert_exit 2 "$missing_exit"
assert_contains "$TEMP_DIR/missing.out" 'REASON=codex-cli-unavailable'

set +e
printf '%s\n' 'review context' | CODEX_BIN="$FAKE_CODEX" \
  bash "$RUNNER" --plan "$TEMP_DIR/no-plan.md" >"$TEMP_DIR/usage.out" 2>&1
usage_exit=$?
set -e
assert_exit 64 "$usage_exit"

set +e
: | CODEX_BIN="$FAKE_CODEX" bash "$RUNNER" --plan "$PLAN" >"$TEMP_DIR/stdin.out" 2>&1
stdin_exit=$?
set -e
assert_exit 64 "$stdin_exit"

printf 'PASS: Bash Codex review runner\n'
