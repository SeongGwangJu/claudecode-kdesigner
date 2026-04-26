#!/bin/bash
# PostToolUse hook (matcher: Bash) — Bash가 git commit 명령을 실행한 직후 save_count 증가.
# safe-save가 commit을 실행하므로 그 시점이 *저장* 1회로 카운트됨.
# 다른 Bash 호출(ls, grep 등)은 카운트 X — git commit 명령이 포함된 경우만.

set -euo pipefail

INPUT="$(cat || true)"

# tool_input.command 추출
extract_command() {
  if command -v jq >/dev/null 2>&1; then
    echo "$INPUT" | jq -r '.tool_input.command // empty'
  else
    # naive fallback — JSON 안 quote escape는 정밀하지 않지만 git commit 매치엔 충분.
    echo "$INPUT" | grep -oE '"command"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/'
  fi
}

extract_session_id() {
  if command -v jq >/dev/null 2>&1; then
    echo "$INPUT" | jq -r '.session_id // empty'
  else
    echo "$INPUT" | grep -oE '"session_id"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/'
  fi
}

CMD="$(extract_command)"
SESSION_ID="$(extract_session_id)"

# git commit 호출만 카운트.
if ! echo "$CMD" | grep -qE '\bgit[[:space:]]+commit\b'; then
  exit 0
fi

if [ -z "${SESSION_ID:-}" ]; then
  exit 0
fi

DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugin-data/kd}"
SESSIONS_DIR="$DATA_DIR/sessions"
STATE_FILE="$SESSIONS_DIR/$SESSION_ID.json"

# state 파일 없으면 SessionStart hook이 안 돌았거나 session_id 매칭 실패. 조용히 스킵.
if [ ! -f "$STATE_FILE" ]; then
  exit 0
fi

if command -v jq >/dev/null 2>&1; then
  TMP="${STATE_FILE}.tmp.$$"
  jq '.save_count = (.save_count // 0) + 1' "$STATE_FILE" > "$TMP" && mv "$TMP" "$STATE_FILE"
else
  # jq 없으면 정밀 갱신 어려움 — 환경에 따라 정확도 떨어지므로 자가 카운트 fallback에 의존.
  exit 0
fi

exit 0
