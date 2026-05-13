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

# 0) K디자이너 활성 가드 (이슈 #1) — 이 plugin이 글로벌 install이라 cwd 무관하게 hook이 로드됨.
#    디자이너 모드 활성 표식이 없으면 silent skip — 일반 프로젝트에서 false positive 차단.
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
if [ ! -f "$PROJECT_DIR/CLAUDE.project.md" ] && [ "${KDESIGNER_ACTIVE:-}" != "1" ]; then
  exit 0
fi

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
# MATCHED_KIND — Skill이 가공·분류에 쓸 *기계 가독 토큰*만. 친화 문장(LABEL/SCENARIO)은 박지 X —
#                케이스 다양성을 hook이 다 못 따라옴. *어떤 톤으로 안내할지*는 SKILL.md 원칙대로
#                모델이 그때그때 컨텍스트(파일·발화 맥락) 보고 자율 가공.
MATCHED_KIND=""
case "$REL" in
  middleware.ts|middleware.js|middleware.mjs|middleware.*.ts|middleware.*.js| \
  src/middleware.ts|src/middleware.js|src/middleware.mjs|src/middleware.*.ts|src/middleware.*.js)
    MATCHED_KIND="middleware" ;;
  app/api/mock/*|src/app/api/mock/*|pages/api/mock/*|src/pages/api/mock/*)
    exit 0 ;;
  app/api/*|pages/api/*|src/app/api/*|src/pages/api/*)
    MATCHED_KIND="api-route" ;;
  lib/design-mode/*|src/lib/design-mode/*)
    exit 0 ;;
  lib/*|src/lib/*)
    MATCHED_KIND="lib-util" ;;
  hooks/*|src/hooks/*)
    MATCHED_KIND="data-hooks" ;;
  stores/*|src/stores/*|store/*|src/store/*)
    MATCHED_KIND="shared-state" ;;
  config/navigation*|src/config/navigation*|config/routes*|src/config/routes*)
    MATCHED_KIND="navigation-config" ;;
  tsconfig.json|tsconfig.*.json|jsconfig.json|.gitignore|.npmrc|.nvmrc)
    MATCHED_KIND="project-config" ;;
  svelte.config.*|astro.config.*|vite.config.*|next.config.*|expo.config.*|app.config.*)
    MATCHED_KIND="framework-config" ;;
  .env|.env.*)
    MATCHED_KIND="env-secret" ;;
  # NOTE: package.json은 case 분기에서 제거(이슈 #2) — 셋업 중 scripts 추가가 흔한 정상 흐름.
  # 의존성·기존 키 변경 위험은 PostToolUse 패턴 가드의 책임 영역(현재 미구현, 향후 결).
esac

# 3) 디자이너 영역 — 위 어디에도 안 잡힌 경우만 통과 (PostToolUse가 패턴 가드)
if [ -z "$MATCHED_KIND" ]; then
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

# 5) JSON deny + *모델 가공 신호* reason
#    reason은 사용자에게 직접 노출 X(deny 모드) — 모델이 받아 publishing-guard Skill을 호출,
#    SKILL.md 원칙대로 *그때그때 컨텍스트(파일·발화)에 맞춰* 친화 응답 생성.
#    hook 자체엔 완성 문구·시나리오·선택지를 박지 X (룰 기반 회피).
REASON="publishing-guard 신호: 경로 \"${REL}\"가 디자이너 영역 밖이에요. 분류 토큰: ${MATCHED_KIND}. publishing-guard Skill을 호출해 SKILL.md §3 원칙대로 디자이너 친화 톤으로 가공해서 안내하세요 — (a)/(b)/(c) 분류 라벨·코드 용어 노출 X, *이 자리가 어떤 일을 하는 곳인지*·*잘못 바뀌면 어떤 운영 사고가 생기나*를 사용자 발화 맥락에 맞춰 풀어 설명, 1️⃣2️⃣3️⃣ 선택지·되돌리기 안전망 포함. 사용자 동의 시 §5 handoff_review_queue push + §6 publishing_allowed 캐시 push로 재시도 통과. 프로젝트별 경계는 CLAUDE.project.md의 publishing-boundary 슬롯에서 조정 가능."

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
