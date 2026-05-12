---
description: |
  개발자에게 인계 정리. 디자이너 영역(`mock/`·더미 데이터·`asset/`) vs 개발자 영역(실제 데이터 연결 필요 위치)을 자동 분리 표기, **회차별 다중 파일** — 매 인계마다 `handoff/{YYMMDD-HHmm KST}-{TOPIC}.md` *별도 파일* 1개 생성(주제는 commit 메시지에서 자동 추출), `handoff/INDEX.md`가 회차 목록·미적용 카운트 자동 갱신. 각 항목 `- [ ]` 체크박스로 *개발자 부분 적용* 추적, 다음 회차는 grep 재계산으로 자연 반영. `publishing-guard`가 (c) 진짜 prod 영향 변경 동의 시 push한 세션 큐(`handoff_review_queue`)를 꺼내 *§디자인 외 변경 — 검토 필요* 섹션 자동 첨부. 인계 직전 `quality-check` + `safe-save`를 자동으로 묶어 깔끔한 회차 시점을 남긴다. 기존 단일 `HANDOFF.md` 있으면 *읽기 전용 archive*로 그대로 두고 새 회차부터 `handoff/` 폴더 사용.

  발동 예시 (사용자 자연어):
  - "개발자한테 넘기기", "인계 정리해줘"
  - "넘길 거 정리해줘", "개발자한테 보낼 거 만들어줘"
  - "이거 마무리하고 넘기자"

  사용 시점: 디자이너가 화면 작업을 마치고 개발자에게 넘기기 직전. 작업 진행 중 저장은 `safe-save`. *여러 번 인계*가 기본 — 매번 새 회차로 누적된다.
model: inherit  # CLAUDE.md §11 — 변경 분류·SCHEMA 추론·TOPIC 산출·디자이너↔개발자 영역 분리가 컨텍스트 의존 (11-G reframe, 기존 sonnet)
---

## 목적
디자이너 작업물을 *그대로 받아 실서비스에 통합 가능한 상태*로 정리한다. 개발자가 1분 안에 "어디를 실제 데이터에 연결해야 하는지" 파악할 수 있게 하는 것이 합격선.

## 발동 조건

### 발동
- "개발자한테 넘기기"/"인계 정리"/"넘길 거 정리" 류 자연어
- 작업 마지막 단계에서 사용자가 "마무리"·"끝났어" + 인계 의도 함께 표현

### 발동 X
- 작업 진행 중 단순 저장 → `safe-save`
- 점검만 원할 때 → `quality-check` 직접

## 처리 흐름

### 1. 인계 직전 점검 (자동 호출)

#### 1.1 `quality-check` 호출 (Task tool, Haiku)
인계 전에 깨진 화면 안 넘어가게 — `quality-check` Skill을 먼저 돌린다(반응형·색 대비·alt·토큰 어긋남).

분기:
| `quality-check` 결과 | 동작 |
|---|---|
| 빨강 1개 이상 | **중단** + "이거 먼저 같이 고치고 넘길까요?" 권유 |
| 노랑만 | 진행하되 노랑 항목을 회차 파일에 *알려진 이슈* 섹션으로 포함 |
| 모두 초록 | 그대로 진행 |

#### 1.2 `auto-validate` 호출 (Task tool, Haiku)
lint·typecheck 통과 확인. fail이면 `error-translator`로 위임 후 재검증.

### 2. 영역 분리 — 디자이너 vs 개발자

PRD §5 export-handoff 핵심 책임. 기존 프로젝트 시나리오에서 *이번 사이클에 디자이너가 추가/변경한* 부분만 회차 파일에 정리해야 함 — 그러지 않으면 옛 mock·옛 import까지 끌어와 개발자에게 잘못된 인계를 주게 된다.

#### 2.0 이번 사이클 변경분 식별 (CHANGED_FILES 산출)

`/kdesigner:프로젝트시작`/`new-service`/`import-existing`/`safe-save`가 박아둔 *디자이너 모드 진입 시점 SHA*를 읽어 그 시점부터 HEAD까지의 변경분만 추린다.

처리 절차:

1. `cat .claude/.kd-session-base 2>/dev/null` 으로 BASE_SHA 추출.
2. **정상 (BASE_SHA 있음 + `git cat-file -e $BASE_SHA` 성공)**:
   ```
   git diff $BASE_SHA..HEAD --name-only --diff-filter=AMR
   ```
   결과를 `CHANGED_FILES` 목록으로 보관. 이번 사이클에 *추가/수정/이름변경* 된 파일만 들어감.
3. **부재 또는 SHA 무효 (fallback)**:
   - `CHANGED_FILES` = 전체 (기존 동작 유지)
   - 응답에 *한계 1줄* 노출:
     > 이번 사이클 시작 시점이 기록되지 않아 전체 파일 기준으로 인계 정리했어요. 일부가 기존 코드와 섞일 수 있어요.

이후 §2.1·§2.2·§3 스캔은 *모두 CHANGED_FILES 안에서만* (fallback 분기는 기존 동작).

#### 2.1 영역 분류 표 (대상: CHANGED_FILES)

| 분류 | 위치·기준 (CHANGED_FILES 안에서) | 회차 파일 표시 |
|---|---|---|
| **디자이너 영역** (그대로 사용) | `components/`, `app/**/page.tsx`, `styles/`, `tailwind.config.*`, `app/globals.css`, `asset/` | "그대로 가져가셔도 돼요" |
| **가짜 데이터** (실서비스 X) | `mock/**/*` | "여기 데이터를 실제 API/DB에 연결해주세요" |
| **연결 지점** (개발자 작업 필요) | 컴포넌트에서 *이번 사이클에 새로 추가된* `mock/` import 줄 | "이 import를 실제 데이터 소스로 교체" |

#### 2.2 mock import 추출 (이번 사이클 추가분만)

- **정상 (BASE_SHA 유효)**:
  ```
  git diff $BASE_SHA..HEAD -- '*.tsx' '*.ts' '*.jsx' '*.js' | grep -E "^\+.*from ['\"].*mock"
  ```
  diff 추가 라인(`+`)에서 mock import만 추림 → *이번 사이클에 새로 도입한* 연결 지점만 잡힘.
- **fallback (BASE_SHA 부재/무효)**:
  ```
  grep -rn "from ['\"].*mock" components/ app/ src/
  ```
  기존 동작 그대로 (전체 grep). §2.0 한계 1줄과 함께 노출.

각 매치 줄을 파일·라인 번호와 함께 회차 파일의 "실제 데이터에 연결해야 할 곳" 표에 박는다.

### 3. 외부 데이터 의존 컴포넌트 표기

회차 파일의 *외부 데이터 의존 컴포넌트* 섹션은 두 영역으로 분리한다 — *기존 참조*(import-existing이 적어둔 것)와 *이번 추가*(이번 사이클에 새로 도입한 hook)는 성격·갱신 시점이 달라 섞이면 개발자 시선이 흐려진다.

#### 3.1 기존 참조 (CLAUDE.project.md의 섹션 참조만)

대상: `import-existing` Skill이 만든 `CLAUDE.project.md`의 `## 외부 데이터 의존 컴포넌트` 섹션.

처리:
- 그 섹션이 *비어있지 않으면* 회차 파일에 그 내용을 *참조*만 (재나열 X, "기존 컴포넌트 의존은 `CLAUDE.project.md` § 외부 데이터 의존 컴포넌트 참조" 한 줄)
- 그 섹션이 *비어있거나 부재*면(new-service 흐름 — `import-existing` 미경유) 이 하위 섹션 자체를 *스킵* (회차 파일에 안 박음)

#### 3.2 이번 추가 (CHANGED_FILES 안에서 *새로 도입한* hook)

대상: §2.0의 CHANGED_FILES 안 컴포넌트 파일.

스캔 패턴 — 다음 중 하나라도 *추가 줄*(`+`)에서 발견되면 회차 파일에 박는다:
- `useAuth`, `useSession`, `useQuery`, `useSWR`, `useMutation` 등 데이터 훅 사용
- 직접 `fetch()` / `axios()` 호출

처리 절차:

1. **정상 (BASE_SHA 유효)**:
   ```
   git diff $BASE_SHA..HEAD -- '*.tsx' '*.ts' '*.jsx' '*.js' \
     | grep -E "^\+.*\b(useAuth|useSession|useQuery|useSWR|useMutation|fetch\(|axios)"
   ```
   diff 추가 라인에서만 매치 → *이번 사이클에 새로 도입한* hook만 잡힘.
2. **fallback (BASE_SHA 부재/무효)**:
   ```
   grep -rnE "\b(useAuth|useSession|useQuery|useSWR|useMutation|fetch\(|axios)" components/ app/ src/
   ```
   기존 동작 (전체 grep). §2.0 한계 1줄과 함께 노출. `CLAUDE.project.md`의 `## 외부 데이터 의존 컴포넌트`에 이미 있는 항목은 중복 표기 X.

매치 결과는 *항상* 회차 파일에 박는다 — 3.1의 기존 참조 섹션 부재 여부와 *무관*. new-service 흐름(import-existing 미경유)에서 만든 화면이 `useAuth`/`useQuery` 등을 새로 도입한 경우에도 누락되지 않게 한다.

#### 3.3 회차 파일 표시 (두 영역 명료하게 분리)

```markdown
## 외부 데이터 의존 컴포넌트

### 기존 컴포넌트 의존
> 자세한 내용은 `CLAUDE.project.md` § 외부 데이터 의존 컴포넌트 참조.
> (이 섹션이 비어있으면 *기존 참조* 항목 자체를 회차 파일에서 생략 — new-service 흐름)

### 이번 사이클에 새로 도입한 데이터 hook
- `app/dashboard/page.tsx:14` — `useAuth()` 호출 추가
- `components/UserCard.tsx:8` — `useQuery(...)` 호출 추가
```

(매치 0건이면 `### 이번 사이클에 새로 도입한 데이터 hook` 섹션은 "이번 사이클에는 새로 도입한 데이터 hook이 없어요" 한 줄로 표시.)

### 3.4 공유 이력 참조 (external-share 연동)

대상: `CLAUDE.project.md`의 `<!-- kd:slot:share-history -->` 슬롯 안 표.

처리:
- 표가 *비어있거나 슬롯 부재*면 *생략* (3.1 기존 참조 패턴과 동일).
- 비어있지 않으면 §4.5 INDEX.md *부재 분기 신규 생성 시*에만 §외부 데이터 의존 컴포넌트 / 공유 이력 섹션 옆에 한 줄 박기(행 개수 + 가장 최근 항목, 자세한 표는 `CLAUDE.project.md` 참조). 회차 파일에선 *재나열 X* — 시점 정보는 commit·파일명에 이미 있고, 공유 이력은 INDEX 한 곳에 단일 진실로 둠.

목적: 개발자가 *이 디자인이 누구에게 언제 노출됐는지* 인계 시 INDEX에서 한눈에 파악.

### 4. 인계 회차 파일 생성 (`handoff/{YYMMDD-HHmm}-{주제}.md` + `INDEX.md` 자동 갱신)

매 인계 = **별도 파일 1개**. `handoff/` 폴더 안에 *시간순 정렬*되는 파일명으로 분리해, 한 파일이 길어지지 않고 개발자가 *회차 단위로 적용·체크* 가능. 같은 폴더의 `INDEX.md`가 *전 회차 미적용 카운트·회차 목록·전 회차 공통 안내*를 자동 갱신.

**개발자 친화 톤** — 회차 파일 본문은 영어 용어 그대로 OK(읽는 대상이 개발자). 단 명확성 우선.

#### 4.1 주제 산출 (`TOPIC`)

§2의 `CHANGED_FILES` + `git diff --stat`을 메인 모델이 *자연 한국어 1줄*로 요약 — `safe-save` §3와 같은 결. 예: "메인 화면 카드 다듬기", "프로필 페이지 추가", "회원가입 흐름 수정".

규칙:
- 25자 이내. 영어 단독 토큰 X.
- *§6 safe-save 위임 메시지에도 같은 TOPIC 사용* — 파일명·회차 본문·commit 메시지가 *한 주제*로 일관.

#### 4.2 파일명 결정 (KST 시간 + slug)

```bash
TS="$(TZ='Asia/Seoul' date +'%y%m%d-%H%M')"   # 예: 260512-1430
```

`TOPIC`을 파일명 slug로 변환:
- 공백·`/`·`\` → `-`
- 한국어 그대로, 영문·숫자 그대로 (kebab-case 강제 X — 디자이너 가독성 우선)
- 결과: `handoff/260512-1430-메인-화면-카드-다듬기.md`

#### 4.3 publishing-guard 큐 pop (§디자인 외 변경 소스)

신호 채널: `publishing-guard` Skill이 (c) 분류 + 사용자 명시 동의 시 `${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugin-data/kd}/sessions/<session_id>.json`의 `handoff_review_queue` 배열에 한 줄씩 push.

처리:

1. 세션 state 파일 — *최근 수정* 파일로 추정 (session_id가 호출 컨텍스트에 안 보일 수 있어):
   ```bash
   DATA_DIR="${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugin-data/kd}"
   STATE_FILE="$(ls -t "$DATA_DIR/sessions/"*.json 2>/dev/null | head -1)"
   ```
2. 부재 또는 `handoff_review_queue` 비어있음 → §디자인 외 변경 섹션 *생략*.
3. `jq` 가용 시 항목 추출 + 비움 (회차 파일 *작성 성공 후*):
   ```bash
   REVIEW_ITEMS="$(jq -r '.handoff_review_queue // [] | .[]' "$STATE_FILE")"
   # ... 파일 작성 후 ...
   jq '.handoff_review_queue = []' "$STATE_FILE" > "$STATE_FILE.tmp" && mv "$STATE_FILE.tmp" "$STATE_FILE"
   ```
   `jq` 부재면 fallback 시도, 실패 시 빈 배열로 진행 (큐 그대로 두면 다음 회차가 다시 흡수 — 멱등).

큐 항목 형식은 `publishing-guard` §5.4와 동일: `- [ ] <파일:라인> — *<변경 종류>* (<영향 1줄>)`.

#### 4.4 회차 파일 생성

`handoff/` 디렉토리 없으면 생성. 회차 파일은 `Write`로 신규 (덮어쓰기 — 같은 분 안에 두 번 호출하면 사용자 의도 모호, 두 번째가 `(2)` 붙이거나 *기존 파일 있어요* 응답으로 중단).

템플릿:

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

각 섹션은 *0건이면 생략*. 단 `## 검증 결과`는 항상.

각 항목 `- [ ]` 체크박스 — 개발자가 적용 후 `- [x]`로 체크.

#### 4.5 `INDEX.md` 자동 갱신

미적용 카운트·회차 수는 *매번 재계산*(grep) — 개발자가 `- [ ]`을 `- [x]`로 체크한 변화도 자연히 반영:
```bash
UNCHECKED_TOTAL="$(grep -hc '^- \[ \] ' ./handoff/*.md 2>/dev/null | awk '{s+=$1} END {print s+0}')"
ROUND_COUNT="$(ls ./handoff/*.md 2>/dev/null | grep -v INDEX.md | wc -l | tr -d ' ')"
```

**부재 분기** — `Write`로 신규 생성:

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

**존재 분기** — 한눈에 두 줄(`Edit`)과 회차 목록 1줄(`## 회차 목록 (최신 순)` 직후 prepend, `Edit`)만 갱신. 적용 완료 추적은 *체크박스 grep 재계산*으로 자연 처리 — 별도 메커니즘 X.

#### 4.6 큐 비움 (post-write)

§4.4 회차 파일·§4.5 INDEX 갱신 성공 후 §4.3 jq 비움. 실패 시 다음 회차가 흡수.

### 5. `mock/` 데이터에 SCHEMA 주석 자동 박기

개발자가 `mock/users.ts` 보고 *어떤 형태로 실제 API를 만들면 되는지* 추론할 수 있게, 각 mock 파일 상단에 타입 힌트 주석을 추가:

```typescript
// SCHEMA: User { id: string, name: string, email: string, avatarUrl?: string }
// 실제 API 응답이 이 형태여야 컴포넌트가 그대로 동작합니다.
export const users = [...]
```

추출 방법:
- `mock/*.ts` 파일에서 export된 데이터의 첫 객체 키·값 타입을 `Read`로 분석
- 이미 `// SCHEMA:` 주석 있으면 건드리지 않음

### 6. 인계 시점 commit (`safe-save` 위임)

인계는 *되돌릴 수 있어야 함*. `safe-save`로 회차 시점을 명시 기록.

위임 메시지(자연어 인자로 전달) — §4.1 `TOPIC` 그대로 사용:
> 인계 정리 — {TOPIC} (handoff/{YYMMDD-HHmm}-{TOPIC-slug}.md 생성, mock 데이터에 SCHEMA 주석 추가)

`safe-save`가 받은 메시지를 commit 메시지로 사용 + commit. push는 사용자에게 묻는다(safe-save 기본 동작).

회차 파일의 `commit: \`<short-sha>\`` 줄은 commit *완료 후* `Edit`으로 채움 (commit 직후 `git rev-parse --short HEAD` 추출).

### 7. 응답 가공 (호출 측 톤)

응답 패턴 (성공 — 첫 회차):
> **인계 정리** 끝났어요 — `handoff/{YYMMDD-HHmm}-{TOPIC}.md` 한 파일에 이번 회차 인계 내용이 들어있어요. `handoff/INDEX.md`엔 전체 회차 한눈 요약.
>
> - **실제 데이터에 연결해야 할 곳**: M곳 (각 파일·줄 번호, `- [ ]` 체크박스)
> - **가짜 데이터**: `mock/` 안 N개 파일 (실제 API 형태 힌트 같이)
>
> 회차 시점도 묶어뒀어요(`commit: <sha>`) — 나중에 이 상태로 다시 돌아올 수 있어요.

응답 패턴 (성공 — 누적 회차, INDEX 이미 있는 경우):
> **인계 정리 — {TOPIC}** 끝났어요. 이번 회차는 `handoff/{YYMMDD-HHmm}-{TOPIC}.md`로 새 파일에 분리해 박았어요. 이전 회차 파일들은 그대로 있어요.
>
> - **이번 회차 새 항목**: M개 (`- [ ]` 체크박스 — 개발자가 적용 후 체크)
> - **전 회차 미적용 합계**: K건 (`handoff/INDEX.md` 한눈에에서 확인)
> - **회차 시점**: `commit: <sha>`

`publishing-guard` 큐에서 *§디자인 외 변경 — 검토 필요* 항목 있으면 응답에 한 줄 추가:
> 이번 사이클에 *디자인 외 변경*도 K건 있어서 회차 파일 안 별도 섹션(*검토 필요*)에 박아뒀어요 — 개발자가 그 부분만 더 꼼꼼히 봐주실 거예요.

`quality-check` 빨강으로 §1.1에서 중단됐다면 진행되지 않음 — 그땐 빨강 항목 응답만.

#### 7.1 fresh-session-guide 자동 트리거 (성공 시 한정)

인계 정리는 *큰 사이클의 마무리*라 새 대화창 권유 질적 게이트가 자동으로 yes. 응답 마지막 줄(다음 행동 제안 직전)에 한 줄 추가:

> 한 사이클 끝났으니 *새 대화창*으로 옮기시는 것도 좋아요 — 잠깐 안내드릴게요.

이어 `fresh-session-guide` Skill을 트리거 — 메인 모델이 그 Skill의 §2 권유 메시지(새 대화 여는 법 + 안심 메시지)를 응답 끝에 직접 박는다 (별도 위임 X). 단, `fresh-session-guide` §발동 X 조건(같은 세션에서 이미 권유함 등)에 걸리면 침묵.

응답 마지막 다음 행동 1개는 `fresh-session-guide` §3의 톤대로 "이어서 다음 작업이 있으시면 새 대화창에서 *이어서 작업하자*로 시작해보세요"로 통일.

## Subagent 위임
- **이 Skill 자체는 메인 모델 컨텍스트** (`model: inherit` — 11-G reframe, CLAUDE.md §11). 변경 분류·SCHEMA 추론·TOPIC 한국어 1줄·외부 데이터 의존 컴포넌트 표기·디자이너↔개발자 영역 분리는 *디자인 컨텍스트 의존*이라 다운그레이드 위험
- 내부 위임 (격리·정형 도구 사유 충족):
  - `quality-check` (Task tool) — 인계 전 점검. *quality-check도 inherit*이라 메인 모델 컨텍스트 흐름은 유지, 인계 단계 격리 효과만
  - `auto-validate` (Task tool, Haiku) — lint/typecheck 통과 확인 (§11 (b)(c))
  - `safe-save` (Task tool, Haiku) — 인계 시점 commit (§11 (b)(c))
  - `error-translator` (메인 가로채기) — 검증·commit 실패 시
- 책임 분리: 이 Skill은 *문서화·정리*만 담당. 코드 수정·개발자 측 통합은 안 함.

## 응답 톤
- 디자이너에게 노출되는 응답은 한국어 + 페르소나 톤 (`designer-persona` 글로벌 원칙)
- `handoff/` 안 파일·INDEX.md *내용*은 개발자 대상이라 영어 용어 사용 OK (읽기 정확성 우선)
- 응답 끝 다음 행동 1개 제안:
  - 성공 + `fresh-session-guide` 권유 동반 시: "이어서 다음 작업이 있으시면 새 대화창에서 *이어서 작업하자*로 시작해보세요"
  - 성공 + 권유 침묵 시: "이제 `handoff/INDEX.md` 한번 같이 훑어볼까요?"
  - 빨강 발견 중단: "이거 먼저 같이 고치고 넘길까요?"

## 의존
- 다른 Skill: `quality-check` (인계 전 점검), `auto-validate` (검증), `safe-save` (회차 시점 commit, §6 TOPIC 메시지 전달), `import-existing` (외부 데이터 의존 컴포넌트 섹션 참조), `external-share` (§공유 이력 슬롯 참조 — §3.4), `publishing-guard` (세션 큐 `handoff_review_queue`를 §4.3에서 pop — 큐 공유 결합도, 직접 호출 X), `error-translator` (실패 시), `designer-persona` (톤), `fresh-session-guide` (인계 성공 시 새 대화 권유 자동 트리거)
- 외부 도구: `Read`/`Glob`/`Grep` (분리 분석), `Write` (`handoff/{YYMMDD-HHmm}-{TOPIC}.md` 회차 파일, `handoff/INDEX.md` 신규), `Edit` (`INDEX.md` 한눈에 카운트·회차 목록 prepend, commit short-sha 사후 채움, `mock/` SCHEMA 주석), `Bash` (`mkdir -p handoff/`, `TZ='Asia/Seoul' date`, `git rev-parse --short HEAD`, `grep`/`ls`/`awk` — 회차·미적용 카운트, `jq` — 큐 pop)
- 세션 state: `${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugin-data/kd}/sessions/<session_id>.json` — R(`handoff_review_queue` pop)·W(소비 후 빈 배열로 갱신). 같은 파일을 `publishing-guard`가 push, `designer-persona`가 `commit_meaning_shown` 키 사용 — 키 단위 비간섭.
- 산출물 경로: `./handoff/{YYMMDD-HHmm}-{TOPIC-slug}.md` (회차별), `./handoff/INDEX.md` (자동 갱신 요약). 기존 단일 `./HANDOFF.md`가 있으면 *읽기 전용 archive*로 그대로 두고 새 회차부터 폴더 사용.
- 참조 파일: `CLAUDE.project.md` (외부 데이터 의존 컴포넌트 섹션, 공유 이력 슬롯)
- 참조: PRD §5 export-handoff, §4 핵심 가치 4번 (안전한 핸드오프), CLAUDE.md §3 비파괴적 git, IMPROVEMENTS §F2-#5, ROADMAP Phase 11-D
