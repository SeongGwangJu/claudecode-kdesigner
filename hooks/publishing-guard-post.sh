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

# 0) K디자이너 활성 가드 (이슈 #1) — 글로벌 install false positive 차단.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
if [ ! -f "$PROJECT_DIR/CLAUDE.project.md" ] && [ "${KDESIGNER_ACTIVE:-}" != "1" ]; then
  exit 0
fi

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
# SIGNALS_KIND — *기계 가독 토큰*만 누적. 친화 풀이는 hook에 박지 X(룰 기반 회피) —
#                모델이 SKILL.md 원칙대로 그때그때 컨텍스트 보고 자율 가공.
SIGNALS_KIND=""
add_signal() {
  SIGNALS_KIND="${SIGNALS_KIND}${SIGNALS_KIND:+,}$1"
}

if echo "$ADDED" | grep -qE '(interface[[:space:]]+\w+Props|type[[:space:]]+\w+Props[[:space:]]*=)'; then
  add_signal "props-signature"
fi
if echo "$ADDED" | grep -qE "from[[:space:]]+['\"]@/(hooks|stores|store|lib/api|api)/"; then
  add_signal "domain-import"
fi
if echo "$ADDED" | grep -qE '\b(useState|useEffect|useCallback|useMemo|useReducer)\b[[:space:]]*[(<]'; then
  add_signal "state-hook"
fi
if echo "$REMOVED" | grep -qE '<Link\b'; then
  add_signal "link-removed"
fi
if echo "$ADDED" | grep -qE '!!|Boolean\('; then
  if echo "$REMOVED" | grep -qE '!!|Boolean\(' ; then : ; else
    add_signal "boolean-cast"
  fi
fi
# active matching·sort·format 알고리즘 교체 휴리스틱: 함수 본문 5+ 라인 추가·제거 동시 발생
ADDED_COUNT=$(echo "$ADDED" | grep -cE '^\+' || true)
REMOVED_COUNT=$(echo "$REMOVED" | grep -cE '^-' || true)
if [ "$ADDED_COUNT" -ge 5 ] && [ "$REMOVED_COUNT" -ge 5 ]; then
  if echo "$DIFF" | grep -qE '(function[[:space:]]+\w+|const[[:space:]]+\w+[[:space:]]*=[[:space:]]*\(.*\)[[:space:]]*=>)'; then
    add_signal "function-replaced"
  fi
fi

[ -z "$SIGNALS_KIND" ] && exit 0

REASON="publishing-guard 신호: 디자이너 영역 안 파일(${REL})에 *디자인 외 영향* 패턴 감지. 분류 토큰: ${SIGNALS_KIND}. publishing-guard Skill을 호출해 SKILL.md §3 원칙대로 디자이너 친화 톤으로 가공 — 분류 라벨·코드 용어 노출 X, *이 변경이 운영에서 어떤 영향을 줄 수 있는지*를 사용자 발화 맥락에 맞춰 풀어 안내, 1️⃣2️⃣3️⃣ 선택지(의도한 변경/시각만/취소)·되돌리기 안전망 포함. 사용자가 의도한 변경 택 시 §5 handoff_review_queue push."

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
