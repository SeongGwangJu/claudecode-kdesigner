# §4 기본 경계 + §5 큐 push + §6 재시도

## §4 기본 경계 (Next.js 기준, 프로젝트 슬롯 부재 시)

`<!-- kd:slot:publishing-boundary -->` 슬롯이 비어있을 때 hook이 적용하는 기본값:

| 영역 | 분류 | 비고 |
|---|---|---|
| `mock/**`·`lib/design-mode/**`·`src/lib/design-mode/**`·`asset/**`·`public/**`·`.env.kdesigner-design` | 허용 | 디자이너 영역 |
| `components/**`·`src/components/**`·`app/**/*.{tsx,jsx}`·`pages/**/*.{tsx,jsx}` (단 `pages/api/` 제외) | 허용 (단 변경 *패턴*은 PostToolUse 가드) | 컴포넌트·페이지 본문 |
| `app/globals.css`·`styles/**`·`**/*.module.css`·`tailwind.config.*` | 허용 | 스타일 |
| `middleware.*`·`app/api/**`(`api/mock/` 제외)·`lib/**`(`design-mode/` 제외)·`hooks/**`·`stores/**`·`config/navigation*`·`config/routes*`·`package.json`·`tsconfig.*`·`.gitignore`·`.env*`(`.env.kdesigner-design` 제외) | 금지 → PreToolUse 차단 | 개발자 영역 |

**왜 Next.js 기준** — 라운드 2 실사용 디자이너 1명의 운영 레포가 Next.js라 데이터 근거가 그쪽. *Vite·Expo·SvelteKit·Astro* 등에서는 `src/lib/server/**`(SvelteKit)·`server/**`(Nuxt) 등 *서버 경계 표현*만 다르고 분류 원칙은 동일 — 사용자가 슬롯에 본 레포 구조로 *허용/금지* 경로를 박아 조정.

## §5 세션 state 큐 push (c 분류 + 동의 시)

`export-handoff` §4.3에서 큐를 pop해 *§디자인 외 변경 — 검토 필요* 섹션을 자동 채우기 위한 신호 채널. 양쪽이 같은 세션 state 파일만 공유 — 직접 호출 X, 결합도 낮음.

처리:

1. `${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugin-data/kd}/sessions/<session_id>.json` 경로 결정. `session_id`는 hook 신호 본문 또는 환경에서 추출.
2. 파일 없으면 *조용히 skip* (SessionStart hook이 도는 환경이 아닐 수 있음 — 큐 없으면 export-handoff가 *섹션 자체*를 만들지 않음).
3. `jq` 가용 시:
   ```bash
   jq --arg item "<item>" '.handoff_review_queue = ((.handoff_review_queue // []) + [$item])' state.json
   ```
   `jq` 부재면 fallback: 간단한 sed/append 시도 (실패해도 응답은 그대로).
4. 큐 항목 형식: `- [ ] <파일:라인> — *<변경 종류>* (<영향 1줄>)` — 예: `- [ ] components/features/messages/ChatRoomItem.tsx:42 — *props 시그니처 변경* (사용처에서 타입 에러 가능)`

변경 종류 어휘: *props 시그니처 변경* / *알고리즘 교체* / *훅 신규 결합* / *접근성 회귀 가능* / *동작 동일한 정리* / *라우팅 메타 변경*.

## §6 PreToolUse 차단 시 *재시도* 흐름

Pre-hook이 *경로 매치*로 deny한 경우, 이 Skill이 동의 받은 뒤 *같은 도구 호출을 다시*. 사용자가 진행을 택했다는 사실 자체가 *디자이너 명시 의도*. 두 번째 호출에서 hook이 또 deny하면 `permissionDecision: ask` 동의 흐름으로 들어가 사용자 1-click으로 통과.

대안 — 일회용 *세션 동의 캐시*: 같은 세션에서 *같은 파일*에 두 번째 동의를 받지 않게 `${CLAUDE_PLUGIN_DATA}/sessions/<session_id>.json`의 `publishing_allowed: ["<rel-path>", ...]` 배열에 push. 다음 hook 호출 시 hook이 그 배열 확인 후 통과. (구현은 hook 측 — 이 Skill은 *push만*)
