#!/bin/bash
# PostToolUse hook (matcher: Bash) — git commit 시 save_count 누적 + fresh-session-guide 자가 발동 신호.
# 처리 결: git commit이 끝나면 (1) save_count를 +1(양적 게이트용 카운트 누적) → (2) 갱신된 state 파일의
# *원본 값*(save_count·started_at·suggested + 마지막 commit 메시지)을 additionalContext로 노출 →
# fresh-session-guide Skill §1 4조건 AND 게이트가 자연 평가 발동.
# 분류 토큰·원본 값만 노출, 친화 풀이·판정·임계치 비교는 SKILL.md 책임 (publishing-guard-post.sh 패턴 응용).

set -euo pipefail

INPUT="$(cat || true)"

# 0) K디자이너 활성 가드 (issue #1 정신 — 글로벌 install false positive 차단)
#    비활성 프로젝트에선 카운트도 신호도 X — fresh-session-guide 발동 자체가 없는 환경에서 무용.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
if [ ! -f "$PROJECT_DIR/CLAUDE.project.md" ] && [ "${KDESIGNER_ACTIVE:-}" != "1" ]; then
  exit 0
fi

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

# jq 가용 시: 카운트 누적 + 원본 값 신호 노출. 부재 시 자가 카운트 fallback(SKILL §1.1)에 의존하고 종료.
if ! command -v jq >/dev/null 2>&1; then
  exit 0
fi

# save_count +1
TMP="${STATE_FILE}.tmp.$$"
jq '.save_count = (.save_count // 0) + 1' "$STATE_FILE" > "$TMP" && mv "$TMP" "$STATE_FILE"

# 신호 노출 — 갱신된 state 파일에서 원본 값만 (판정·임계치 비교 X — SKILL §1 책임).
# publishing-guard-post.sh와 같은 결: hook은 *원본 값과 평가 지시*만, 친화 풀이는 SKILL이 컨텍스트 보고 자율 가공.
SAVE_COUNT="$(jq -r '.save_count // 0' "$STATE_FILE")"
STARTED_AT="$(jq -r '.started_at // empty' "$STATE_FILE")"
SUGGESTED="$(jq -r '.suggested // false' "$STATE_FILE")"
LAST_MSG="$(git log -1 --format=%B HEAD 2>/dev/null | tr '\n' ' ' | head -c 200 || true)"

REASON="fresh-session-guide 신호: save_count=${SAVE_COUNT}, started_at=${STARTED_AT}, suggested=${SUGGESTED}, last_commit_message=\"${LAST_MSG}\". fresh-session-guide Skill §1 4조건 AND 게이트로 평가 — 양적 §1.1(임계치는 SKILL 본문에 박혀있음, hook은 원본 값만)·질적 §1.2(last_commit_message로 큰 사이클 closer 여부 추론)·재권유 차단 §1.3·사용자 차단 §1.4. 통과 시 §2 권유, 미통과 시 침묵. 임계치 비교·완성 문구는 SKILL이 자율 가공(hook은 원본 값만 노출 원칙)."

jq -n --arg r "$REASON" '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: $r
  }
}'

exit 0
