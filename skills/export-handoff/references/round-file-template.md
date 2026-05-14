# 회차 파일·INDEX.md 템플릿

매 인계 = `handoff/{YYMMDD-HHmm}-{TOPIC-slug}.md` 별도 파일 1개. `handoff/INDEX.md`가 회차 목록·미적용 카운트 자동 갱신.

## TOPIC 산출

`safe-save` §3 결 — `CHANGED_FILES` + `git diff --stat`을 메인 모델이 *한국어 1줄*로. 25자 이내, 영어 단독 토큰 X. `safe-save` 위임 메시지와 *같은* TOPIC 사용(파일명·회차 본문·commit 메시지 일관).

예: "메인 화면 카드 다듬기", "프로필 페이지 추가", "회원가입 흐름 수정".

## 파일명 결정

```bash
TS="$(TZ='Asia/Seoul' date +'%y%m%d-%H%M')"   # 260512-1430
```

TOPIC slug — 공백·`/`·`\` → `-`, 한국어 그대로. kebab-case 강제 X (디자이너 가독성 우선).

결과: `handoff/260512-1430-메인-화면-카드-다듬기.md`

같은 분 안 두 번째 호출 — `(2)` 붙이거나 *기존 파일 있어요* 응답으로 중단.

## 회차 파일 본문

```markdown
# 인계 — {TOPIC}

- 생성: {YYYY-MM-DD HH:mm} KST
- commit: `{short-sha}`

## 실제 데이터에 연결해야 할 곳
- [ ] `app/dashboard/page.tsx:12` — `import { users } from '@/mock/users'` → 실제 사용자 API

## 이번 사이클에 새로 도입한 데이터 hook
- [ ] `components/UserCard.tsx:8` — `useQuery(...)` 호출 추가

## 가짜 데이터 (이번 추가)
- [ ] `mock/users.ts` — 사용자 목록 (10건). `// SCHEMA:` 주석 있음

## ⚠️ 디자인 외 변경 — 검토 필요
- [ ] `components/Foo.tsx:42` — *props 시그니처 변경* (사용처 타입 에러 가능)

> 위 항목은 디자이너가 *명시 동의 후* 진행한 변경이에요. 디자인 의도(시각 표현)는 같지만 prod 동작도 함께 바뀌니 *되돌리거나 보강*할지 검토가 필요해요.

## 알려진 이슈 (quality-check 노랑)
- [ ] `components/Header.tsx` — 모바일 반응형 일부 미적용

## 검증 결과
- lint ✅ · typecheck ✅ · quality-check 빨강 0건 노랑 K건
```

규칙:
- 0건 섹션은 생략. 단 `## 검증 결과`는 항상.
- 각 항목 `- [ ]` — 개발자가 적용 후 `- [x]`.
- `commit:` 줄은 §safe-save 위임 *완료 후* `git rev-parse --short HEAD`로 채움.

## INDEX.md — 부재 분기 (신규 생성)

```markdown
# Handoff INDEX — {서비스명}

> *매 회차 = 별도 파일*(`handoff/` 폴더). 각 항목 `- [ ]`는 개발자가 적용·검토 완료 후 `- [x]`로 체크해주세요.

## 한눈에
- **인계 회차**: {ROUND_COUNT}회 (가장 최근: {YYMMDD-HHmm} {TOPIC})
- **미적용 변경**: {UNCHECKED_TOTAL}개 (전 회차 누적)
- **스택**: {추출 결과}

## 회차 목록 (최신 순)
- [{YYMMDD-HHmm} {TOPIC}](./{YYMMDD-HHmm}-{TOPIC-slug}.md) — 미적용 {N}건

## 그대로 사용 가능 (전 회차 공통)
- `components/**`, `app/**/page.tsx` 또는 라우트, `tailwind.config.*`/토큰 정의, `asset/**`

## 외부 데이터 의존 컴포넌트 / 공유 이력
> 자세한 내용은 `CLAUDE.project.md` § 외부 데이터 의존 컴포넌트 / § 공유 이력 참조.
> (해당 섹션이 비어있으면 이 한 줄도 생략.)
```

루트에 기존 단일 `HANDOFF.md`가 있으면 *그대로 둠*. 한눈에 끝에 1줄 추가:

> 이전 인계 기록(`HANDOFF.md`)이 있어요 — *읽기 전용 archive*로 두고, 이번 회차부터 `handoff/` 폴더에 분리해 누적하고 있어요.

## INDEX.md — 존재 분기 (갱신)

한눈에 두 줄·회차 목록 1줄 prepend만 `Edit`. 적용 완료 추적은 *체크박스 grep 재계산*으로 자연 처리:

```bash
UNCHECKED_TOTAL="$(grep -hc '^- \[ \] ' ./handoff/*.md 2>/dev/null | awk '{s+=$1} END {print s+0}')"
ROUND_COUNT="$(ls ./handoff/*.md 2>/dev/null | grep -v INDEX.md | wc -l | tr -d ' ')"
```

## publishing-guard 큐 pop

세션 state 파일 — *최근 수정* 파일로 추정 (session_id가 호출 컨텍스트에 안 보일 수 있음):

```bash
DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugin-data/kd}"
STATE_FILE="$(ls -t "$DATA_DIR/sessions/"*.json 2>/dev/null | head -1)"
```

부재 또는 `handoff_review_queue` 비어있음 → *§디자인 외 변경* 섹션 생략.

`jq` 가용 시:

```bash
REVIEW_ITEMS="$(jq -r '.handoff_review_queue // [] | .[]' "$STATE_FILE")"
# ... 회차 파일 작성 성공 후 ...
jq '.handoff_review_queue = []' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
```

큐 항목 형식은 `publishing-guard` §5.4와 동일: `- [ ] <파일:라인> — *<변경 종류>* (<영향 1줄>)`. 큐 그대로 두면 다음 회차가 다시 흡수 — 멱등.

## mock SCHEMA 주석

`mock/*.ts` 파일 상단에 타입 힌트:

```typescript
// SCHEMA: User { id: string, name: string, email: string, avatarUrl?: string }
// 실제 API 응답이 이 형태여야 컴포넌트가 그대로 동작합니다.
export const users = [...]
```

이미 `// SCHEMA:` 주석 있으면 건드리지 X.
