---
description: |
  개발자에게 인계 정리. 디자이너 영역(`mock/`·더미 데이터·`asset/`) vs 개발자 영역(실제 데이터 연결 필요 위치)을 자동 분리 표기, 개발자용 README(`HANDOFF.md`) 자동 생성 — 어디를 실제 데이터에 연결해야 하는지·가짜 데이터 위치·인계 시점 commit 해시까지 포함. 인계 직전 `quality-check` + `safe-save`를 자동으로 묶어 깔끔한 인계 시점을 남긴다.

  발동 예시 (사용자 자연어):
  - "개발자한테 넘기기", "인계 정리해줘"
  - "넘길 거 정리해줘", "개발자한테 보낼 거 만들어줘"
  - "이거 마무리하고 넘기자"

  사용 시점: 디자이너가 화면 작업을 마치고 개발자에게 넘기기 직전. 작업 진행 중 저장은 `safe-save`.
model: sonnet
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
| 노랑만 | 진행하되 노랑 항목을 인계 README에 *알려진 이슈* 섹션으로 포함 |
| 모두 초록 | 그대로 진행 |

#### 1.2 `auto-validate` 호출 (Task tool, Haiku)
lint·typecheck 통과 확인. fail이면 `error-translator`로 위임 후 재검증.

### 2. 영역 분리 — 디자이너 vs 개발자

PRD §5 export-handoff 핵심 책임. 기존 프로젝트 시나리오에서 *이번 사이클에 디자이너가 추가/변경한* 부분만 인계 README에 정리해야 함 — 그러지 않으면 옛 mock·옛 import까지 끌어와 개발자에게 잘못된 인계를 주게 된다.

#### 2.0 이번 사이클 변경분 식별 (CHANGED_FILES 산출)

`/kdesigner:디자인초기설정`/`new-service`/`import-existing`/`safe-save`가 박아둔 *디자이너 모드 진입 시점 SHA*를 읽어 그 시점부터 HEAD까지의 변경분만 추린다.

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

| 분류 | 위치·기준 (CHANGED_FILES 안에서) | 인계 README 표시 |
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

각 매치 줄을 파일·라인 번호와 함께 인계 README의 "실제 데이터에 연결해야 할 곳" 표에 박는다.

### 3. 외부 데이터 의존 컴포넌트 표기

인계 README의 *외부 데이터 의존 컴포넌트* 섹션은 두 영역으로 분리한다 — *기존 참조*(import-existing이 적어둔 것)와 *이번 추가*(이번 사이클에 새로 도입한 hook)는 성격·갱신 시점이 달라 섞이면 개발자 시선이 흐려진다.

#### 3.1 기존 참조 (CLAUDE.project.md의 섹션 참조만)

대상: `import-existing` Skill이 만든 `CLAUDE.project.md`의 `## 외부 데이터 의존 컴포넌트` 섹션.

처리:
- 그 섹션이 *비어있지 않으면* 인계 README에 그 내용을 *참조*만 (재나열 X, "기존 컴포넌트 의존은 `CLAUDE.project.md` § 외부 데이터 의존 컴포넌트 참조" 한 줄)
- 그 섹션이 *비어있거나 부재*면(new-service 흐름 — `import-existing` 미경유) 이 하위 섹션 자체를 *스킵* (인계 README에 안 박음)

#### 3.2 이번 추가 (CHANGED_FILES 안에서 *새로 도입한* hook)

대상: §2.0의 CHANGED_FILES 안 컴포넌트 파일.

스캔 패턴 — 다음 중 하나라도 *추가 줄*(`+`)에서 발견되면 인계 README에 박는다:
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

매치 결과는 *항상* 인계 README에 박는다 — 3.1의 기존 참조 섹션 부재 여부와 *무관*. new-service 흐름(import-existing 미경유)에서 만든 화면이 `useAuth`/`useQuery` 등을 새로 도입한 경우에도 누락되지 않게 한다.

#### 3.3 인계 README 표시 (두 영역 명료하게 분리)

```markdown
## 외부 데이터 의존 컴포넌트

### 기존 컴포넌트 의존
> 자세한 내용은 `CLAUDE.project.md` § 외부 데이터 의존 컴포넌트 참조.
> (이 섹션이 비어있으면 *기존 참조* 항목 자체를 인계 README에서 생략 — new-service 흐름)

### 이번 사이클에 새로 도입한 데이터 hook
- `app/dashboard/page.tsx:14` — `useAuth()` 호출 추가
- `components/UserCard.tsx:8` — `useQuery(...)` 호출 추가
```

(매치 0건이면 `### 이번 사이클에 새로 도입한 데이터 hook` 섹션은 "이번 사이클에는 새로 도입한 데이터 hook이 없어요" 한 줄로 표시.)

### 3.4 공유 이력 참조 (external-share 연동)

대상: `CLAUDE.project.md`의 `<!-- kd:slot:share-history -->` 슬롯 안 표.

처리:
- 표에 *데이터 행이 1줄 이상*이면 인계 README에 §공유 이력 섹션 박기:
  - 행 개수(N) + 가장 최근 항목(일자·대상) 1줄
  - 자세한 표는 *재나열 X*, `CLAUDE.project.md` 참조 한 줄
- 표가 *비어있거나 슬롯 부재*면 §공유 이력 섹션 자체 *생략* (3.1 기존 참조 패턴과 동일)

목적: 개발자가 *이 디자인이 누구에게 언제 노출됐는지* 인계 시 한눈에 파악. 클라이언트 시안인지 내부 검토용인지에 따라 데이터 연결 우선순위가 달라짐.

### 4. 인계 README 생성 (`HANDOFF.md`)

루트에 `HANDOFF.md` 생성. **개발자 친화 톤** — 이 한 파일은 영어 용어 그대로 써도 됨(읽는 대상이 개발자). 단 명확성 우선.

템플릿:

```markdown
# Handoff — <서비스명>

> 디자이너가 만든 화면을 받아 실서비스에 통합하기 위한 안내. 생성: <YYYY-MM-DD>, commit: `<short-sha>`.

## 한눈에
- **스택**: Next.js / Tailwind / shadcn/ui (또는 추출된 스택)
- **화면 수**: N개
- **연결 필요 지점**: M곳
- **알려진 이슈**: K개

## 그대로 사용 가능
- `components/**` — 재사용 컴포넌트
- `app/**/page.tsx` — 화면 라우트
- `tailwind.config.*`, `app/globals.css` — 디자인 토큰
- `asset/**` — 이미지·아이콘

## 실제 데이터에 연결해야 할 곳

| 파일:라인 | 현재 (가짜 데이터) | 교체 대상 |
|---|---|---|
| `app/dashboard/page.tsx:12` | `import { users } from '@/mock/users'` | 실제 사용자 API |
| `components/UserCard.tsx:8` | `useMockAuth()` | 프로젝트의 인증 훅 |

> 위 import 경로(`@/mock/...`)를 실제 데이터 소스로 교체하면 동작합니다.

## 가짜 데이터 위치
- `mock/users.ts` — 사용자 목록 (10건)
- `mock/products.ts` — 상품 목록 (24건)
- `mock/auth.ts` — 가짜 로그인 사용자 (1명)

각 파일에는 `// SCHEMA:` 주석으로 타입 힌트가 있습니다.

## 외부 데이터 의존 컴포넌트
- `UserAvatar` (`components/UserAvatar.tsx`) — `useAuth()` 의존, `mock/auth.ts`로 미리보기 중
- ...

## 공유 이력
> 자세한 내용은 `CLAUDE.project.md` § 공유 이력 참조.
> 이 디자인은 인계 전 N회 외부 공유됨 (가장 최근: <YYYY-MM-DD HH:mm> · <대상>).
> (이 섹션은 §공유 이력이 비어있으면 *생략* — `external-share` 한 번도 안 쓴 흐름.)

## 알려진 이슈 (quality-check 노랑)
- `components/Header.tsx` — 모바일 반응형 일부 미적용 (디자이너가 두고 넘김)
- ...

## 검증 결과 (인계 시점)
- `npm run lint` ✅
- `npm run typecheck` ✅
- `quality-check` 빨강 0건, 노랑 K건

## 디자이너 작업 시점 commit
- `<short-sha>` — <commit 메시지>
- 이 시점으로 되돌리려면 `git checkout <short-sha>`
```

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

인계는 *되돌릴 수 있어야 함*. `safe-save`로 commit 시점을 명시 기록:

위임 메시지(자연어 인자로 전달):
> 인계 정리 — `HANDOFF.md` 생성, mock 데이터에 SCHEMA 주석 추가

`safe-save`가 자동으로 한국어 commit 메시지 생성 + commit. push는 사용자에게 묻는다(safe-save 기본 동작).

`HANDOFF.md`에 이 commit의 short-sha를 박아 *인계 시점이 명확*해지게.

### 7. 응답 가공 (호출 측 톤)

응답 패턴 (성공):
> **인계 정리** 끝났어요 — `HANDOFF.md` 한 파일에 개발자가 알아야 할 모든 게 들어있어요.
>
> - **그대로 가져갈 수 있는 부분**: 화면·컴포넌트·디자인 토큰
> - **실제 데이터에 연결해야 할 곳**: M곳 (각 파일·줄 번호 표시)
> - **가짜 데이터**: `mock/` 안 N개 파일 (실제 API 형태 힌트도 같이)
>
> 인계 시점도 한 시점으로 묶어뒀어요(`commit: <sha>`) — 나중에 이 상태로 다시 돌아올 수 있어요.

`quality-check` 빨강으로 §1.1에서 중단됐다면 진행되지 않음 — 그땐 빨강 항목 응답만.

#### 7.1 fresh-session-guide 자동 트리거 (성공 시 한정)

인계 정리는 *큰 사이클의 마무리*라 새 대화창 권유 질적 게이트가 자동으로 yes. 응답 마지막 줄(다음 행동 제안 직전)에 한 줄 추가:

> 한 사이클 끝났으니 *새 대화창*으로 옮기시는 것도 좋아요 — 잠깐 안내드릴게요.

이어 `fresh-session-guide` Skill을 트리거 — 메인 모델이 그 Skill의 §2 권유 메시지(새 대화 여는 법 + 안심 메시지)를 응답 끝에 직접 박는다 (별도 위임 X). 단, `fresh-session-guide` §발동 X 조건(같은 세션에서 이미 권유함 등)에 걸리면 침묵.

응답 마지막 다음 행동 1개는 `fresh-session-guide` §3의 톤대로 "이어서 다음 작업이 있으시면 새 대화창에서 *이어서 작업하자*로 시작해보세요"로 통일.

## Subagent 위임
- **이 Skill 자체가 Sonnet Subagent로 동작** (`model: sonnet`) — 분리·정리·README 생성, 중간 난이도 (PRD §12)
- 내부 위임:
  - `quality-check` (Task tool, Haiku) — 인계 전 점검
  - `auto-validate` (Task tool, Haiku) — lint/typecheck 통과 확인
  - `safe-save` (Task tool, Haiku) — 인계 시점 commit
  - `error-translator` (메인 가로채기) — 검증·commit 실패 시
- 책임 분리: 이 Skill은 *문서화·정리*만 담당. 코드 수정·개발자 측 통합은 안 함.

## 응답 톤
- 디자이너에게 노출되는 응답은 한국어 + 페르소나 톤 (`designer-persona` 글로벌 원칙)
- `HANDOFF.md` *내용*은 개발자 대상이라 영어 용어 사용 OK (읽기 정확성 우선)
- 응답 끝 다음 행동 1개 제안:
  - 성공 + `fresh-session-guide` 권유 동반 시: "이어서 다음 작업이 있으시면 새 대화창에서 *이어서 작업하자*로 시작해보세요"
  - 성공 + 권유 침묵 시(같은 세션 1회 이미 노출 등): "이제 `HANDOFF.md` 한번 같이 훑어볼까요?"
  - 빨강 발견 중단: "이거 먼저 같이 고치고 넘길까요?"

## 의존
- 다른 Skill: `quality-check` (인계 전 점검), `auto-validate` (검증), `safe-save` (인계 시점 commit), `import-existing` (외부 데이터 의존 컴포넌트 섹션 참조), `external-share` (§공유 이력 슬롯 참조 — §3.4), `error-translator` (실패 시), `designer-persona` (톤), `fresh-session-guide` (인계 성공 시 새 대화 권유 자동 트리거)
- 외부 도구: `Read`/`Glob`/`Grep` (분리 분석), `Write` (`HANDOFF.md`), `Edit` (`mock/` SCHEMA 주석 추가), `Bash` (`git rev-parse --short HEAD` — 인계 commit 해시)
- 참조 파일: `CLAUDE.project.md` (외부 데이터 의존 컴포넌트 섹션)
- 참조: PRD §5 export-handoff, §4 핵심 가치 4번 (안전한 핸드오프), CLAUDE.md §3 비파괴적 git
