#!/bin/bash
# PostToolUse hook (matcher: Edit|Write|MultiEdit) — 퍼블리싱 패턴 가드 (F2-#6)
# 디자이너 영역 안(components/, app/, pages/) 파일이 변경된 *직후* git diff에서
# *디자인 외 영향* 패턴이 발견되면 additionalContext로 publishing-guard Skill 호출 유도.
# 분류·동의·큐 push는 Skill 본문에 정의 — 이 hook은 *신호*만.

set -euo pipefail

INPUT="$(cat || true)"

extract_field() {
  local field="$1"
  if command -v jq >/dev/null 2>&1; then
    echo "$INPUT" | jq -r ".${field} // empty"
  else
    echo "$INPUT" | grep -oE "\"${field##*.}\"[[:space:]]*:[[:space:]]*\"[^\"]+\"" | head -1 | sed -E 's/.*"([^"]+)"$/\1/'
  fi
}

FILE_PATH="$(extract_field 'tool_input.file_path')"
[ -z "${FILE_PATH:-}" ] && exit 0

# 상대 경로
CWD="$(pwd)"
case "$FILE_PATH" in
  "$CWD/"*) REL="${FILE_PATH#$CWD/}" ;;
  /*)       REL="$FILE_PATH" ;;
  *)        REL="$FILE_PATH" ;;
esac

# 디자이너 영역 안만 패턴 검사 — 그 외는 pre-hook이 처리
INSIDE=0
case "$REL" in
  components/*|src/components/*) INSIDE=1 ;;
  app/*|src/app/*) INSIDE=1 ;;
  pages/*|src/pages/*) INSIDE=1 ;;
esac
[ "$INSIDE" -eq 0 ] && exit 0

# api 라우트는 디자이너 영역 아님 (pre-hook이 처리)
case "$REL" in
  app/api/*|src/app/api/*|pages/api/*|src/pages/api/*) exit 0 ;;
esac

# tsx/jsx/ts만 (css·json·md는 패턴 가드 X)
case "$REL" in
  *.tsx|*.jsx|*.ts|*.mts|*.cts) ;;
  *) exit 0 ;;
esac

# git diff — 저장소 아니거나 추적 안 되면 skip
DIFF="$(git diff --no-color HEAD -- "$REL" 2>/dev/null || true)"
if [ -z "$DIFF" ]; then
  # 새 파일이면 staged diff or 전체 내용으로 fallback
  DIFF="$(git diff --no-color --cached -- "$REL" 2>/dev/null || true)"
  [ -z "$DIFF" ] && exit 0
fi

# 추가 라인 / 제거 라인 분리
ADDED="$(echo "$DIFF" | grep -E '^\+[^+]' || true)"
REMOVED="$(echo "$DIFF" | grep -E '^-[^-]' || true)"

# 패턴 탐지 (CLAUDE.md §12 — 범용 표현, 특정 파일·hash 종속 X)
SIGNALS=""
add_signal() { SIGNALS="${SIGNALS}${SIGNALS:+, }$1"; }

if echo "$ADDED" | grep -qE '(interface[[:space:]]+\w+Props|type[[:space:]]+\w+Props[[:space:]]*=)'; then
  add_signal "props 시그니처 변경"
fi
if echo "$ADDED" | grep -qE "from[[:space:]]+['\"]@/(hooks|stores|store|lib/api|api)/"; then
  add_signal "도메인 hook·store import 신규"
fi
if echo "$ADDED" | grep -qE '\b(useState|useEffect|useCallback|useMemo|useReducer)\b[[:space:]]*[(<]'; then
  add_signal "상태 흐름 hook 신규"
fi
if echo "$REMOVED" | grep -qE '<Link\b'; then
  add_signal "<Link> 제거 (접근성 회귀 가능)"
fi
if echo "$ADDED" | grep -qE '!!|Boolean\('; then
  if echo "$REMOVED" | grep -qE '!!|Boolean\(' ; then : ; else
    add_signal "boolean 변환 추가 (동작 동일한 정리)"
  fi
fi
# active matching·sort·format 알고리즘 교체 휴리스틱: 함수 본문 5+ 라인 추가·제거 동시 발생
ADDED_COUNT=$(echo "$ADDED" | grep -cE '^\+' || true)
REMOVED_COUNT=$(echo "$REMOVED" | grep -cE '^-' || true)
if [ "$ADDED_COUNT" -ge 5 ] && [ "$REMOVED_COUNT" -ge 5 ]; then
  if echo "$DIFF" | grep -qE '(function[[:space:]]+\w+|const[[:space:]]+\w+[[:space:]]*=[[:space:]]*\(.*\)[[:space:]]*=>)'; then
    add_signal "함수 본문 교체 (알고리즘 변경 가능성)"
  fi
fi

[ -z "$SIGNALS" ] && exit 0

REASON="디자이너 영역 안 파일이지만 *디자인 외 영향* 패턴이 감지됐어요 (${REL}). publishing-guard Skill을 호출해 (a) 격리 OK / (b) 격리 부족 / (c) 진짜 prod 영향 분류로 사용자에게 톤 차별화해 안내하세요. (c)면 명시 동의 + handoff_review_queue push. 신호: ${SIGNALS}"

if command -v jq >/dev/null 2>&1; then
  jq -n --arg r "$REASON" '{
    hookSpecificOutput: {
      hookEventName: "PostToolUse",
      additionalContext: $r
    }
  }'
else
  SAFE_R="$(printf '%s' "$REASON" | tr -d '\n' | sed 's/"/\\"/g')"
  printf '{"hookSpecificOutput":{"hookEventName":"PostToolUse","additionalContext":"%s"}}\n' "$SAFE_R"
fi

exit 0
