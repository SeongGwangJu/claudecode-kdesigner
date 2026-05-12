#!/bin/bash
# PreToolUse hook (matcher: Edit|Write|MultiEdit) — 퍼블리싱 경계 가드 (F2-#6)
# file_path가 *디자이너 영역 밖*(middleware·api·hooks·stores·navigation·config·env 등) 매치 시,
# permissionDecision: deny + reason으로 publishing-guard Skill 호출 유도.
# 분류·동의·큐 push는 Skill 본문에 정의 — 이 hook은 *신호*만.
#
# 세션 동의 캐시: ${CLAUDE_PLUGIN_DATA}/sessions/<session_id>.json `publishing_allowed: [...]`
# 같은 세션에서 같은 경로 두 번째 호출 시 통과 (Skill이 §6에서 push).
#
# 분기 순서:
#   1) 명시 허용 영역(즉시 통과)
#   2) 금지 영역(MATCHED 분류명 결정 후 deny)
#   3) 디자이너 영역(통과 — PostToolUse 패턴 가드가 처리)
#   4) 그 외(보수적 통과)

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

SESSION_ID="$(extract_field 'session_id')"

CWD="$(pwd)"
case "$FILE_PATH" in
  "$CWD/"*) REL="${FILE_PATH#$CWD/}" ;;
  /*)       REL="$FILE_PATH" ;;
  *)        REL="$FILE_PATH" ;;
esac

# 1) 명시 허용 영역
case "$REL" in
  mock/*|lib/design-mode/*|src/lib/design-mode/*|asset/*|public/*|assets/*) exit 0 ;;
  .env.kdesigner-design) exit 0 ;;
  CLAUDE.project.md|CLAUDE.md|HANDOFF.md|DESIGN.md) exit 0 ;;
  .claude/.kd-session-base|*.gitkeep) exit 0 ;;
  *.kd-backup-*|*.kd-archived-*|*.kd-migrate-*) exit 0 ;;
esac

# 2) 금지 영역 매치
MATCHED=""
case "$REL" in
  middleware.ts|middleware.js|middleware.mjs|middleware.*.ts|middleware.*.js)
    MATCHED="middleware (요청 가로채기 영역)" ;;
  src/middleware.ts|src/middleware.js|src/middleware.mjs|src/middleware.*.ts|src/middleware.*.js)
    MATCHED="middleware (요청 가로채기 영역)" ;;
  app/api/mock/*|src/app/api/mock/*|pages/api/mock/*|src/pages/api/mock/*)
    exit 0 ;;
  app/api/*|pages/api/*|src/app/api/*|src/pages/api/*)
    MATCHED="API 라우트 (백엔드 영역)" ;;
  lib/design-mode/*|src/lib/design-mode/*)
    exit 0 ;;
  lib/*|src/lib/*)
    MATCHED="lib/ 유틸 (런타임 로직 영역)" ;;
  hooks/*|src/hooks/*)
    MATCHED="hooks/ 커스텀 훅 (데이터 흐름 영역)" ;;
  stores/*|src/stores/*|store/*|src/store/*)
    MATCHED="stores/ 전역 상태 (도메인 store 영역)" ;;
  config/navigation*|src/config/navigation*|config/routes*|src/config/routes*)
    MATCHED="네비게이션/라우팅 메타 (UX 동작 영역)" ;;
  package.json|tsconfig.json|tsconfig.*.json|jsconfig.json|.gitignore|.npmrc|.nvmrc)
    MATCHED="프로젝트 설정 파일 (개발자 영역)" ;;
  svelte.config.*|astro.config.*|vite.config.*|next.config.*|expo.config.*|app.config.*)
    MATCHED="프레임워크 설정 파일 (개발자 영역)" ;;
  .env|.env.*)
    MATCHED="환경변수 파일 (운영 비밀 영역)" ;;
esac

# 3) 디자이너 영역 — 위 어디에도 안 잡힌 경우만 통과 (PostToolUse가 패턴 가드)
if [ -z "$MATCHED" ]; then
  case "$REL" in
    components/*|src/components/*) exit 0 ;;
    app/*|src/app/*|pages/*|src/pages/*) exit 0 ;;
    styles/*|src/styles/*|*.module.css) exit 0 ;;
    tailwind.config.*|postcss.config.*) exit 0 ;;
  esac
  # 그 외 — 보수적 통과
  exit 0
fi

# 4) 세션 동의 캐시 — 같은 경로 재시도면 통과
if [ -n "${SESSION_ID:-}" ] && command -v jq >/dev/null 2>&1; then
  DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugin-data/kd}"
  STATE_FILE="$DATA_DIR/sessions/$SESSION_ID.json"
  if [ -f "$STATE_FILE" ]; then
    if jq -e --arg p "$REL" '(.publishing_allowed // []) | index($p)' "$STATE_FILE" >/dev/null 2>&1; then
      exit 0
    fi
  fi
fi

# 5) JSON deny + Skill 호출 유도
REASON="이 파일은 디자이너 영역 밖이에요(${MATCHED}). publishing-guard Skill을 호출해 (a) 격리 OK / (b) 격리 부족 / (c) 진짜 prod 영향 분류로 디자이너에게 안내하고, 명시 동의 받은 뒤 (c)면 HANDOFF.md 검토필요 큐(handoff_review_queue)에 push 후 진행. 경로 매치: ${REL}. 프로젝트별 경계는 CLAUDE.project.md의 publishing-boundary 슬롯에서 조정 가능."

if command -v jq >/dev/null 2>&1; then
  jq -n --arg r "$REASON" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
else
  SAFE_R="$(printf '%s' "$REASON" | tr -d '\n' | sed 's/"/\\"/g')"
  printf '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"%s"}}\n' "$SAFE_R"
fi

exit 0
