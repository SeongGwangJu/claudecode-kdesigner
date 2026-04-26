#!/bin/bash
# SessionStart hook — fresh-session-guide의 양적 게이트용 state 파일 초기화.
# 입력(stdin JSON)에서 session_id 추출, 기존 state 있으면 *덮지 않고* 종료(resume·compact 시 누적 보존).
# CLAUDE_PLUGIN_DATA는 플러그인 영구 저장 디렉토리(공식 spec).

set -euo pipefail

# stdin이 JSON이라 가정. session_id 추출 (jq 없으면 grep으로 fallback).
INPUT="$(cat || true)"

extract_session_id() {
  if command -v jq >/dev/null 2>&1; then
    echo "$INPUT" | jq -r '.session_id // empty'
  else
    echo "$INPUT" | grep -oE '"session_id"[[:space:]]*:[[:space:]]*"[^"]+"' | head -1 | sed -E 's/.*"([^"]+)"$/\1/'
  fi
}

SESSION_ID="$(extract_session_id)"
if [ -z "${SESSION_ID:-}" ]; then
  # session_id를 못 잡으면 조용히 종료 — 게이트는 자가 카운트 fallback으로 떨어짐.
  exit 0
fi

DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugin-data/kd}"
SESSIONS_DIR="$DATA_DIR/sessions"
mkdir -p "$SESSIONS_DIR"

STATE_FILE="$SESSIONS_DIR/$SESSION_ID.json"

# 이미 있으면 *덮지 않음* — resume·compact 시 save_count·started_at 보존.
if [ -f "$STATE_FILE" ]; then
  exit 0
fi

NOW="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
cat > "$STATE_FILE" <<EOF
{
  "session_id": "$SESSION_ID",
  "started_at": "$NOW",
  "save_count": 0,
  "suggested": false
}
EOF

exit 0
