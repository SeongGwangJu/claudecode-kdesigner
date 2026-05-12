---
description: |
  디자이너가 *디자인 외 영역*(인증·라우팅·도메인 store·hook 결합·props 시그니처·알고리즘 교체 등)을 변경하려 할 때, 가드 hook이 신호를 보내면 깨어나 *(a) 격리 OK / (b) 격리 부족 / (c) 진짜 prod 영향* 3분류로 톤 차별화해 응답한다. (c) 분류 + 사용자 명시 동의 시 세션 state `handoff_review_queue`에 한 줄 push해 다음 인계 회차 HANDOFF.md 검토필요 섹션에 자동 첨부(F2-#5 연동). 디자이너 작업 흐름은 끊지 X — *분리·기록* 우선, 차단 X.

  발동 예시:
  - PreToolUse hook이 *디자이너 영역 밖 파일 경로 매치*로 깨움 (`middleware*`/`app/api/**`/`lib/**`/`hooks/**`/`stores/**`/`config/navigation*` 등)
  - PostToolUse hook이 *디자인 외 변경 패턴*(props 시그니처·도메인 hook import·상태 hook 신규·`<Link>` 제거 등) 감지로 깨움
  - 디자이너가 직접 "이 파일 손대도 돼?" / "여기 코드 좀 정리할게" / "이 컴포넌트 props 바꿔도 돼?" 발화로 사전 호출

  사용 시점: Edit/Write/MultiEdit가 prod 경계 코드에 영향 줄 때. 가드는 *디자이너 영역 안*은 침묵, *경계 밖·디자인 외 패턴*에서만 발동.
model: inherit  # CLAUDE.md §11 — 가드 분류·동의 흐름·응답 톤이 디자인 컨텍스트 의존, 다운그레이드 X
---

## 목적
디자이너가 *디자인 의도 외* prod 동작을 함께 바꾸는 사이드이펙트를 *차단·분리·기록*한다. *차단보다 분리·기록 우선* — 디자이너 흐름을 끊지 X. (c) 진짜 prod 영향만 명시 동의 + 자동 인계 큐 push.

## 발동 조건

### 발동
- PreToolUse hook이 *경로 매치*로 신호 (`hookSpecificOutput.permissionDecisionReason`에 `publishing-guard` 언급)
- PostToolUse hook이 *패턴 매치*로 신호 (`additionalContext`에 `publishing-guard` 언급 + `신호: ...` 목록)
- 디자이너 사전 자연어("이 파일 손대도 돼?")

### 발동 X
- 디자이너 영역 안(`components/**` Tailwind class·CSS 변수·문자열 리터럴만 변경) → hook 자체가 신호 X
- `mock/**`·`lib/design-mode/**`·`asset/**`·`.env.kdesigner-design` → 허용 영역, 가드 침묵
- 디자인 토큰 변경(`tailwind.config`·`globals.css`) → `design-system-guard` 영역, 여기서 발동 X

## 처리 흐름

### §1. 경계 정의 읽기

1. `Read ./CLAUDE.project.md` — `<!-- kd:slot:publishing-boundary -->` 슬롯 본문 확인.
2. 슬롯에 *프로젝트별 경계*가 박혀 있으면 그게 단일 진실 (사용자/개발자가 본 레포 구조에 맞게 조정).
3. 슬롯이 *비어있거나 부재*면 hook 기본값(§4 표) 적용 — Next.js 기준 가정 + *왜 그 가정*인지 응답 본문에 1줄 안내(다른 프레임워크면 사용자에게 슬롯 편집 권유).

### §2. 변경 분류 (a) / (b) / (c)

훅에서 받은 *파일 경로*와 *변경 신호*를 분류한다. 분류는 *변경 위치 + 변경 종류* 함수 — 토글 유무가 아니다.

| 분류 | 판정 기준 | 가드 행동 |
|---|---|---|
| **(a) 격리 OK** | `lib/design-mode/**`/`mock/**` 안 변경 / `IS_DESIGN_MODE` early return 분기 / Tailwind class·CSS 변수·문자열 리터럴만 변경 | *침묵* 또는 가벼운 인지 1줄. 동의 X. queue push X |
| **(b) 격리 부족** | 디자인 모드 의도이나 prod 흐름과 섞임 (예: 토글 검사 없이 `process.env.<x>` 분기 추가) | *보강 제안* + AskUserQuestion 1회 ("토글 안으로 옮길까요? / 그대로 두기 / 잘 모르겠어요"). queue push X |
| **(c) 진짜 prod 영향** | props 시그니처 변경 / 함수 알고리즘 교체 / 도메인 hook·store import 신규 / 상태 흐름 hook(`useState`/`useEffect`/`useCallback`) 신규 / `<Link>` 제거 / 라우팅 메타 / boolean 변환 같은 "동작 동일한 정리" | *명시 동의* + queue push (§5). 진행 시 commit 메시지에 `[review-needed]` 태그 권유 |

판정 시 *변경 의도 — 시각 표현인가 데이터 흐름인가*가 핵심 신호. 시각 표현이면 (a), 데이터 흐름이면 (c). 애매하면 (b)로 묻기.

### §3. 응답 톤 (분류별 차별화)

**(a) 격리 OK** — 짧고 가벼운 인지 1줄, 강제 X:
> 디자인 모드 토글이 깨끗하게 격리됐어요. 인계 시 `DESIGN_MODE` 환경변수만 끄면 원복돼요.

이후 별도 동의 요청 없이 그대로 진행. 사용자가 무관심해도 OK.

**(b) 격리 부족** — 보강 제안:
> 이 분기 *디자인 모드 전용 같은데*, 토글 검사가 빠져있어 운영에서도 함께 켜질 수 있어요.
> `if (IS_DESIGN_MODE)` 블록 안으로 옮기면 깔끔하게 격리돼요.

`AskUserQuestion`:
- 토글 안으로 옮길게요 (안전·권장)
- 그대로 두기 (이유 있어서)
- 잘 모르겠어요 → 권장(옮기기)

**(c) 진짜 prod 영향** — 명시 동의 + 인계 기록:
> 이 변경은 *디자인 의도 외* prod 동작도 함께 바뀌는 부분이 있어요 — *{{변경 종류}}*.
> 시각 표현만 바꾸려면 (a)처럼 디자인 모드 전용으로 분리해드릴 수 있어요.
> 의도하신 게 맞다면 진행하되 *개발자 검토가 필요*하게 인계 노트에 자동 기록할게요.

`AskUserQuestion`:
- 의도한 변경 — 진행 + 인계 노트에 기록 (개발자 검토)
- 시각만 바꾸고 싶어 — (a) 패턴으로 분리해줘
- 취소 — 손대지 X
- 잘 모르겠어요 → *분리*(시각만) 권장

진행 분기 선택 시 §5 queue push.

### §4. 기본 경계 (Next.js 기준, 프로젝트 슬롯 부재 시)

`<!-- kd:slot:publishing-boundary -->` 슬롯이 비어있을 때 hook이 적용하는 기본값:

| 영역 | 분류 | 비고 |
|---|---|---|
| `mock/**`, `lib/design-mode/**`, `src/lib/design-mode/**`, `asset/**`, `public/**`, `.env.kdesigner-design` | 허용 | 디자이너 영역 |
| `components/**`, `src/components/**`, `app/**/*.{tsx,jsx}`, `pages/**/*.{tsx,jsx}` (단 `pages/api/` 제외) | 허용 (단 변경 *패턴*은 PostToolUse 가드 대상) | 컴포넌트·페이지 본문 |
| `app/globals.css`, `styles/**`, `**/*.module.css`, `tailwind.config.*` | 허용 | 스타일 |
| `middleware.*`, `app/api/**` (`api/mock/` 제외), `lib/**`(`design-mode/` 제외), `hooks/**`, `stores/**`/`store/**`, `config/navigation*`, `config/routes*`, `package.json`, `tsconfig.*`, `.gitignore`, `.env*`(`.env.kdesigner-design` 제외) | 금지 → PreToolUse 차단 | 개발자 영역 |

**왜 Next.js 기준** — 라운드 2 실사용 디자이너 1명의 운영 레포가 Next.js라 데이터 근거가 그쪽에 있음. *Vite·Expo·SvelteKit·Astro* 등에서는 `src/lib/server/**`(SvelteKit)·`server/**`(Nuxt) 등 *서버 경계 표현*만 다르고 분류 원칙은 동일 — 사용자가 슬롯에 본 레포 구조로 *허용/금지* 경로를 박아 조정.

### §5. 세션 state queue push (c 분류 + 동의 시)

`export-handoff` §4.3에서 큐를 pop해 *§디자인 외 변경 — 검토 필요* 섹션을 자동 채우기 위한 신호 채널. 양쪽이 같은 세션 state 파일만 공유 — 직접 호출 X, 결합도 낮음.

처리:
1. `${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugin-data/kd}/sessions/<session_id>.json` 경로 결정. `session_id`는 hook 신호 본문 또는 환경에서 추출.
2. 파일 없으면 *조용히 skip* (SessionStart hook이 도는 환경이 아닐 수 있음 — 큐 없으면 export-handoff가 *섹션 자체*를 만들지 않음).
3. 있으면 `jq` 가용 시:
   ```bash
   jq --arg item "<item>" '.handoff_review_queue = ((.handoff_review_queue // []) + [$item])' state.json
   ```
   `jq` 부재면 fallback: 간단한 sed/append 시도 (실패해도 응답은 그대로).
4. 큐 항목 형식: `- [ ] <파일:라인> — *<변경 종류>* (<영향 1줄>)` — 예: `- [ ] components/features/messages/ChatRoomItem.tsx:42 — *props 시그니처 변경* (사용처에서 타입 에러 가능)`

변경 종류 어휘(IMPROVEMENTS §F2-#5 §디자인 외 변경): *props 시그니처 변경* / *알고리즘 교체* / *훅 신규 결합* / *접근성 회귀 가능* / *동작 동일한 정리* / *라우팅 메타 변경*.

### §6. PreToolUse 차단 시 *재시도* 흐름

Pre-hook이 *경로 매치*로 deny한 경우, 이 Skill이 동의 받은 뒤 *같은 도구 호출을 다시*. 사용자가 진행을 택했다는 사실 자체가 *디자이너 명시 의도*. 두 번째 호출에서 hook이 또 deny하면 `permissionDecision: ask` 동의 흐름으로 들어가 사용자 1-click으로 통과.

대안 — 일회용 *세션 동의 캐시*: 같은 세션에서 *같은 파일*에 두 번째 동의를 받지 않게 `${CLAUDE_PLUGIN_DATA}/sessions/<session_id>.json`의 `publishing_allowed: ["<rel-path>", ...]` 배열에 push. 다음 hook 호출 시 hook이 그 배열 확인 후 통과. (구현은 hook 측에서 — 이 Skill은 *push만*)

### §7. 자가 점검

응답 직전 체크:
- [ ] 분류 (a)/(b)/(c) 중 *하나만* 선택했는가 (애매하면 (b))
- [ ] (c) 진행 동의 시 §5 queue push *실행*했는가
- [ ] 응답 톤이 분류와 일치(가벼움/보강 제안/명시 동의)
- [ ] 디자이너 영역 안 변경엔 발동 X (오발 시 그대로 진행)
- [ ] 가드 패턴에 *특정 파일명·hash* 박지 않았는가 (CLAUDE.md §12 — 범용 표현만)

## Subagent 위임
- 이 Skill 자체: `inherit` — 분류·응답 톤·동의 흐름이 디자인 컨텍스트 의존 (CLAUDE.md §11 (c) 정형 도구만 아님). 모델 다운그레이드 X.
- hook 자체는 Skill 호출 *신호*만. 분류·동의·queue push는 Skill 책임.

## 응답 톤
- 한국어, 비유 + 용어 한글 병기 (`designer-persona`)
- 분류별 차별화 (§3) — 가벼움/보강/명시 동의
- *차단보다 분리·기록* — "이거 하지 마세요" X, "이렇게 하면 더 안전해요" O
- (c) 진행 동의 후엔 *안심* 톤 — "기록해뒀어요. 인계 시 자동으로 검토 항목에 올라가요"
- 응답 끝 다음 행동 1개 + 자연어 1개 (글로벌 §7) — 분리 진행 시 "이제 시각만 바꿔드릴게요 — '**저장해줘**' 한 마디면 돼요"

## 의존
- 다른 Skill: `import-existing`(§3-D 격리 폴더 셋업 — 가드의 *경계 정의* 기반), `export-handoff`(§4.3에서 큐 pop → `handoff/{YYMMDD-HHmm}-{TOPIC}.md` 안 *§디자인 외 변경 — 검토 필요* 섹션화), `safe-save`(commit 메시지 `[review-needed]` 태그 권유)
- 외부 도구: `Read`/`AskUserQuestion`/`Bash`(`jq`/`mkdir`/`echo`/`git diff`)
- 템플릿: `CLAUDE.project.md` `<!-- kd:slot:publishing-boundary -->` 슬롯
- Hook: `plugin/hooks/hooks.json` 안 PreToolUse(`publishing-guard-pre.sh`) + PostToolUse(`publishing-guard-post.sh`)
- 추적: IMPROVEMENTS §F2-#6, ROADMAP Phase 11-C, F2-#5 큐 공유
