#!/usr/bin/env bash
set -euo pipefail

PRIMARY_MODEL="gpt-5.6-sol"
FALLBACK_MODEL="gpt-5.5"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROMPT_FILE="$SCRIPT_DIR/../codex-review-prompt.md"
CODEX_BIN="${CODEX_BIN:-codex}"
PLAN_PATH=""

usage_error() {
  printf 'Error: %s\n' "$1" >&2
  exit 64
}

emit_status() {
  local status="$1"
  local model="$2"
  local reason="${3:-}"
  if [[ -n "$reason" ]]; then
    printf 'EXECUTING_PLANS_REVIEW_STATUS=%s MODEL=%s REASON=%s\n' "$status" "$model" "$reason"
  else
    printf 'EXECUTING_PLANS_REVIEW_STATUS=%s MODEL=%s\n' "$status" "$model"
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --plan)
      [[ $# -ge 2 ]] || usage_error '--plan requires a path'
      PLAN_PATH="$2"
      shift 2
      ;;
    *)
      usage_error "unknown argument: $1"
      ;;
  esac
done

[[ -n "$PLAN_PATH" ]] || usage_error '--plan is required'
[[ -f "$PLAN_PATH" && -r "$PLAN_PATH" ]] || usage_error "plan is not readable: $PLAN_PATH"
[[ -f "$PROMPT_FILE" && -r "$PROMPT_FILE" ]] || usage_error "review prompt is not readable: $PROMPT_FILE"

PLAN_PATH="$(cd "$(dirname "$PLAN_PATH")" && pwd -P)/$(basename "$PLAN_PATH")"
CONTEXT_FILE="$(mktemp)"
REQUEST_FILE="$(mktemp)"
OUTPUT_FILE="$(mktemp)"
ERROR_FILE="$(mktemp)"
PLAN_STATE_FILE="$(mktemp)"
trap 'rm -f "$CONTEXT_FILE" "$REQUEST_FILE" "$OUTPUT_FILE" "$ERROR_FILE" "$PLAN_STATE_FILE"' EXIT

cat > "$CONTEXT_FILE"
[[ -s "$CONTEXT_FILE" ]] || usage_error 'stdin review context is required'

awk '
function flush_task() {
  if (task == "") return
  if (!saw_execution || !saw_verification) {
    print "MALFORMED:" task
  } else if (!complete) {
    print "INCOMPLETE:" task
  } else if (!verified) {
    print "EXPECTED:" task
  }
}
{
  if (!in_fence) {
    if ($0 ~ /^```/) {
      fence = $0
      sub(/[^`].*$/, "", fence)
      in_fence = 1
      next
    }
    if ($0 ~ /^~~~/) {
      fence = $0
      sub(/[^~].*$/, "", fence)
      in_fence = 1
      next
    }
  } else {
    closing = $0
    if (index(closing, fence) == 1) {
      closing = substr(closing, length(fence) + 1)
      if (closing ~ /^[[:space:]]*$/) {
        in_fence = 0
      }
    }
    next
  }
}
/^### Task [0-9]+:/ {
  flush_task()
  task = $0
  sub(/^### Task /, "", task)
  sub(/:.*/, "", task)
  saw_execution = 0
  saw_verification = 0
  complete = 0
  verified = 0
  next
}
/^[*][*]Execution:[*][*] / {
  saw_execution = 1
  complete = ($0 == "**Execution:** [x] complete")
  next
}
/^[*][*]Codex verification:[*][*] / {
  saw_verification = 1
  verified = ($0 ~ /^\*\*Codex verification:\*\* VERIFIED \(round [0-9]+, (gpt-5\.6-sol|gpt-5\.5)\)$/)
  next
}
END { flush_task() }
' "$PLAN_PATH" > "$PLAN_STATE_FILE"

if grep -Eq '^(MALFORMED|INCOMPLETE):' "$PLAN_STATE_FILE"; then
  cat "$PLAN_STATE_FILE" >&2
  usage_error 'every plan task must have complete execution and a valid Codex verification field'
fi

EXPECTED_TASKS=()
while IFS=: read -r kind task_id; do
  [[ "$kind" == "EXPECTED" ]] || continue
  EXPECTED_TASKS+=("$task_id")
done < "$PLAN_STATE_FILE"
[[ "${#EXPECTED_TASKS[@]}" -gt 0 ]] || usage_error 'plan has no pending tasks to review'
EXPECTED_CSV="$(IFS=,; printf '%s' "${EXPECTED_TASKS[*]}")"

{
  cat "$PROMPT_FILE"
  printf '\n\n# Runtime Review Input\n\n'
  printf 'Plan path: %s\n' "$PLAN_PATH"
  printf 'Expected task IDs: %s\n' "$EXPECTED_CSV"
  printf '\nCompletion context:\n'
  cat "$CONTEXT_FILE"
  printf '\n'
} > "$REQUEST_FILE"

if [[ "$CODEX_BIN" == */* ]]; then
  [[ -x "$CODEX_BIN" ]] || {
    emit_status SKIPPED none codex-cli-unavailable
    exit 2
  }
elif ! command -v "$CODEX_BIN" >/dev/null 2>&1; then
  emit_status SKIPPED none codex-cli-unavailable
  exit 2
fi

ATTEMPT_EXIT=0
ATTEMPT_TEXT=""
SELECTED_MODEL=""
FAILURE_REASON=""

invoke_codex() {
  local model="$1"
  : > "$OUTPUT_FILE"
  : > "$ERROR_FILE"
  if "$CODEX_BIN" review --uncommitted \
    -c "model=\"$model\"" \
    -c 'model_reasoning_effort="high"' \
    - < "$REQUEST_FILE" > "$OUTPUT_FILE" 2> "$ERROR_FILE"; then
    ATTEMPT_EXIT=0
  else
    ATTEMPT_EXIT=$?
  fi
  cat "$OUTPUT_FILE"
  cat "$ERROR_FILE" >&2
  ATTEMPT_TEXT="$(cat "$OUTPUT_FILE"; cat "$ERROR_FILE")"
  return "$ATTEMPT_EXIT"
}

is_fallback_error() {
  printf '%s\n' "$ATTEMPT_TEXT" | grep -Eiq \
    'rate.?limit|quota|usage limit|too many requests|model.*(unavailable|not available|not found|unsupported|does not exist)|unsupported.*model'
}

validate_protocol() {
  local verdict_count=0
  local verdict=""
  local line task_id task_state
  local observed_ids=()
  local observed_states=()
  local expected observed count index finding_task matched
  local has_blocked=0
  local has_p01=0

  verdict_count="$(grep -Ec '^VERDICT: (PASS|BLOCKED)$' "$OUTPUT_FILE" || true)"
  [[ "$verdict_count" -eq 1 ]] || return 2
  verdict="$(grep -E '^VERDICT: (PASS|BLOCKED)$' "$OUTPUT_FILE" | cut -d' ' -f2)"

  while IFS= read -r line; do
    task_id="${line#- Task }"
    task_id="${task_id%%:*}"
    task_state="${line##*: }"
    observed_ids+=("$task_id")
    observed_states+=("$task_state")
    [[ "$task_state" == "BLOCKED" ]] && has_blocked=1
  done < <(grep -E '^- Task [0-9]+: (VERIFIED|BLOCKED)$' "$OUTPUT_FILE" || true)

  [[ "${#observed_ids[@]}" -eq "${#EXPECTED_TASKS[@]}" ]] || return 2
  for expected in "${EXPECTED_TASKS[@]}"; do
    count=0
    for observed in "${observed_ids[@]}"; do
      [[ "$observed" == "$expected" ]] && count=$((count + 1))
    done
    [[ "$count" -eq 1 ]] || return 2
  done
  for observed in "${observed_ids[@]}"; do
    count=0
    for expected in "${EXPECTED_TASKS[@]}"; do
      [[ "$observed" == "$expected" ]] && count=$((count + 1))
    done
    [[ "$count" -eq 1 ]] || return 2
  done

  if grep -Eq '^- \[P[01]\] ' "$OUTPUT_FILE"; then
    has_p01=1
  fi

  while IFS= read -r line; do
    finding_task="${line#*] Task }"
    finding_task="${finding_task%% *}"
    matched=0
    for ((index = 0; index < ${#observed_ids[@]}; index++)); do
      if [[ "${observed_ids[$index]}" == "$finding_task" && "${observed_states[$index]}" == "BLOCKED" ]]; then
        matched=1
      fi
    done
    [[ "$matched" -eq 1 ]] || return 2
  done < <(grep -E '^- \[P[01]\] Task [0-9]+ ' "$OUTPUT_FILE" || true)

  for ((index = 0; index < ${#observed_ids[@]}; index++)); do
    if [[ "${observed_states[$index]}" == "BLOCKED" ]]; then
      grep -Eq "^- \[P[01]\] Task ${observed_ids[$index]} " "$OUTPUT_FILE" || return 2
    fi
  done

  if [[ "$verdict" == "PASS" ]]; then
    [[ "$has_blocked" -eq 0 && "$has_p01" -eq 0 ]] || return 2
    return 0
  fi

  [[ "$has_blocked" -eq 1 || "$has_p01" -eq 1 ]] || return 2
  return 1
}

review_model() {
  local model="$1"
  local allow_fallback="$2"
  local attempt protocol_result
  for attempt in 1 2; do
    if ! invoke_codex "$model"; then
      if [[ "$allow_fallback" -eq 1 ]] && is_fallback_error; then
        FAILURE_REASON="primary-model-or-quota-unavailable"
        return 10
      fi
      FAILURE_REASON="codex-unavailable"
      return 20
    fi

    if validate_protocol; then
      SELECTED_MODEL="$model"
      return 0
    else
      protocol_result=$?
    fi
    if [[ "$protocol_result" -eq 1 ]]; then
      SELECTED_MODEL="$model"
      return 1
    fi
  done
  SELECTED_MODEL="$model"
  FAILURE_REASON="malformed-output"
  return 20
}

if review_model "$PRIMARY_MODEL" 1; then
  review_result=0
else
  review_result=$?
fi

case "$review_result" in
  0)
    emit_status PASS "$SELECTED_MODEL"
    exit 0
    ;;
  1)
    emit_status BLOCKED "$SELECTED_MODEL"
    exit 1
    ;;
  10)
    if review_model "$FALLBACK_MODEL" 0; then
      review_result=0
    else
      review_result=$?
    fi
    case "$review_result" in
      0)
        emit_status PASS "$SELECTED_MODEL"
        exit 0
        ;;
      1)
        emit_status BLOCKED "$SELECTED_MODEL"
        exit 1
        ;;
      *)
        emit_status SKIPPED "$FALLBACK_MODEL" "$FAILURE_REASON"
        exit 2
        ;;
    esac
    ;;
  *)
    emit_status SKIPPED "${SELECTED_MODEL:-$PRIMARY_MODEL}" "$FAILURE_REASON"
    exit 2
    ;;
esac
