---
description: |
  기존 프로젝트에 디자이너가 안전하게 끼어들기. 디자인 시스템 존재 여부 자동 진단 → (있으면 추출, 없으면 만들기 권유 메시지) → 컴포넌트 스캔으로 hook·props·variant 자동 문서화 → `CLAUDE.project.md`에 컴포넌트 인덱스 첫 생성. 기존 코드 훼손 위험을 최소화한다.

  발동 예시 (사용자 자연어):
  - "기존 프로젝트에서 가져오기", "회사 레포에 끼어들어서 작업하고 싶어"
  - "이미 있는 코드에 디자인 추가", "이 프로젝트에 디자이너 모드 켜줘"
  - "있는 거 분석해서 셋업해줘"

  사용 시점: 빈 디렉토리가 아닌 기존 코드베이스에서 디자이너 작업 시작. `package.json` 또는 `components/` 등 작업 흔적이 있을 때.
model: sonnet
---

## 목적
기존 코드 훼손 위험을 최소화하며 디자이너가 끼어들 수 있는 *단일 참조점*(컴포넌트 인덱스 + 디자인 시스템 메모)을 만든다. *읽기·문서화 중심*, 코드 수정은 폴더 추가(`mock/`, `asset/`)·문서 추가만 — 기존 파일 수정은 명시 동의 없이는 X.

## 발동 조건

### 발동
- "기존 프로젝트에서 가져오기"/"회사 레포 끼어들기"/"이미 있는 코드에 디자인" 류 자연어
- `/kdesigner:디자인초기설정` 직후 비어있지 않은 디렉토리 감지 시 자연 권유
- `new-service` 시작 시 §1 가드에서 기존 작업 흔적 발견 시 권유

### 발동 X
- 완전히 빈 디렉토리 → `new-service` 우선
- 디자인 토큰 *변경* 의도 ("색 좀 바꿔줘") → `design-system-guard`

## 처리 흐름

### 1. 기존 상태 진단 (읽기만)

`Glob`/`Read`로 핵심 파일 빠르게 확인. **수정 X, 진단 O**.

| 확인 항목 | 도구 |
|---|---|
| `package.json` (스택·매니저 추론) | `Read` |
| `tsconfig.json` 존재 | `Glob` |
| `tailwind.config.*`, `app/globals.css`, `styles/globals.css` | `Glob` + `Read` |
| `components/` 또는 `src/components/` | `Glob` |
| `components.json` (shadcn/ui 마커) | `Glob` |
| 디자인 토큰 파일 (`theme/*`, `tokens/*`, `design-system/*`) | `Glob` |

진단 결과를 변수로 정리:
- `pkgManager` (lockfile 기준), `framework` (next/vite/expo/etc), `hasShadcn`, `hasTailwind`, `hasTokens`, `hasComponentsDir`

### 2. 디자인 시스템 존재 여부 판정

판정 기준:

| 조건 | 분류 |
|---|---|
| `components.json` (shadcn) + `tailwind.config.*` + `globals.css`에 CSS variables 존재 | **있음 (shadcn 류)** |
| 별도 토큰 파일(`theme/*`, `tokens/*` 등) 명시적 존재 | **있음 (커스텀)** |
| `tailwind.config.*`에 `theme.extend.colors`만 일부 박혀 있고 토큰화 안 됨 | **부분만 있음** |
| Tailwind도 토큰도 없음, 인라인 스타일/CSS 그대로 | **없음** |

### 3-A. 디자인 시스템 *있음* — 추출·요약

`Read`로 토큰 정의 파일을 직접 읽어 `CLAUDE.project.md`에 *요약*.

추출 대상:
- 색 토큰 (primary/secondary/muted/accent 등)
- spacing scale (4·8·16·24 류)
- radius (sm/md/lg/full)
- typography (font-sans/font-serif, 본문 크기 기준)

요약 포맷 (CLAUDE.project.md):
```markdown
## 디자인 시스템 토큰 (이 프로젝트의 사실)
- 색: primary `hsl(...)`, secondary `hsl(...)` ... (총 N개)
- 둥글기: `--radius` 0.5rem 기준 (sm/md/lg)
- 본문 폰트: Inter, 16px
- 정의 위치: `app/globals.css`, `tailwind.config.ts`
```

> ⚠️ 한계: `tailwind.config.*`이 동적 코드(`theme`이 함수 호출이거나 외부 파일을 합쳐 가져오는 경우)면 토큰 추출이 부분만 될 수 있어요. 그땐 `CLAUDE.project.md` 토큰 섹션을 사용자가 1회 다듬어주시면 가장 정확해요.

### 3-B. 디자인 시스템 *없음* — 만들기 권유 (메시지만)

PRD §10 위험 + ROADMAP O-5: **1차에선 권유 메시지만**. 자동 생성 X.

응답 패턴:
> 이 프로젝트는 **공통 디자인 약속**(`design system`)이 아직 정해져 있지 않은 것 같아요. 색·간격·둥글기 같은 공통 기준이 없으면 화면마다 따로 놀게 돼요.
>
> 두 가지 길이 있어요:
> - **개발자에게 요청** — 가장 안전해요. "어떤 색·둥글기·간격을 기준으로 쓸지 정해주세요"라고 부탁해보세요.
> - **지금 일단 만들어 보기** — 가능은 한데, 나중에 개발자 기준과 충돌할 수 있어요. (지금 만드는 흐름은 다음 버전에서 추가될 예정이에요.)
>
> 일단은 **있는 그대로 받아서 진행**할 수 있어요 — 컴포넌트만 정리해드릴게요.

진행은 §4로 이어감. 만들기 자동 흐름은 ROADMAP O-5 추적, 1차 미구현.

### 3-C. *부분만 있음* — 정리 권유

요약은 추출하되, 응답에 "토큰화가 일부만 되어 있어서 새 화면 만들 때 일관성이 흔들릴 수 있어요" 한 줄 첨부. §3-A와 동일하게 진행.

### 4. 컴포넌트 스캔 + 인덱스 첫 생성

이 Skill의 *핵심 산출물*. CLAUDE.md §컴포넌트 인덱스 형식대로 `CLAUDE.project.md`에 일괄 생성.

#### 4.1 컴포넌트 파일 발견
`Glob`으로 후보 위치 모두 스캔:
- `components/**/*.{tsx,jsx}`
- `src/components/**/*.{tsx,jsx}`
- `app/**/*.{tsx,jsx}` 중 컴포넌트 패턴 (default export + PascalCase)

#### 4.2 각 컴포넌트 분석
파일 단위로 `Read` → 다음 추출:

| 추출 항목 | 추출 방법 |
|---|---|
| 이름 | default export 함수명 또는 named export PascalCase |
| 경로 | 파일 상대 경로 |
| 핵심 props | 함수 인자 타입 (`Props` interface 또는 inline) — 1~3개 핵심만 |
| variant | `variant`/`size`/`color` 같은 union string prop의 값 추출 |
| 의존 hook | 컴포넌트 내부에서 호출하는 `use*` (커스텀 hook 포함) |

대규모 프로젝트는 무거울 수 있음 — *50개 상한*. 넘으면 `components/ui/*` 같은 디자인 시스템 베이스만 우선, 나머지는 "..." 표시 + 사용자 안내.

#### 4.3 인덱스 라인 형식

CLAUDE.md §컴포넌트 인덱스 형식 그대로:

```
- `Button` · `components/ui/Button.tsx` · `variant: primary|secondary|ghost`, `size: sm|md|lg` · 기본 액션 버튼
- `Card` · `components/ui/Card.tsx` · (props 단순) · 콘텐츠 묶음 박스
- `UserAvatar` · `components/UserAvatar.tsx` · `size: sm|md`, `useAuth()` 의존 · 로그인한 사용자 표시
```

`useAuth()` 같은 hook 의존은 **더미 환경에서 동작 가능한지 판단의 핵심** — 디자이너가 이 컴포넌트를 더미 데이터로 미리보기 할 때 막힐 수 있는 부분.

#### 4.4 hook 의존 처리 (디자이너 보호)
컴포넌트가 외부 데이터 hook(`useAuth`, `useQuery`, `useSession` 등)에 의존하면 디자이너 더미 환경에서 깨질 위험 → 인덱스 라인 끝에 ⚠️ 표시 + `mock/` 활용 안내를 별도 섹션으로 추가:

```markdown
## 외부 데이터 의존 컴포넌트 (더미 환경 주의)
- `UserAvatar` — `useAuth()` 의존. 미리보기 하려면 `mock/auth.ts`에 가짜 사용자 박아두는 게 안전해요.
```

### 5. 디자이너 폴더 규약 추가

기존 폴더 *건드리지 않고* 누락된 것만 추가:

| 폴더 | 동작 |
|---|---|
| `asset/` | 없으면 `.gitkeep`으로 생성. `public/` 또는 `assets/`가 이미 있으면 그쪽으로 통일 안내(만들지 않음) |
| `mock/` | 없으면 `.gitkeep`으로 생성. `__mocks__/`/`fixtures/` 있으면 통일 안내 |
| `components/` | 이미 있음 가정 (없으면 *프로젝트 자체가 의심* — 진행 중단) |

### 6. `package.json` scripts 보장

`auto-validate` 표준 키 점검:

| 키 | 부재 시 동작 |
|---|---|
| `lint` | 사용자에게 묻고 추가 (이미 lint 도구 결정되어 있을 수 있음) |
| `typecheck` | 없으면 `tsc --noEmit` 추가 (단, `tsconfig.json` 있을 때만) |

기존 scripts와 충돌하면 **묻지 말고 건드리지 않음** — 위험 회피. 응답에 "lint/typecheck 명령이 표준이 아니어서 자동 검증이 일부 제한될 수 있어요" 한 줄 첨부.

### 7. `CLAUDE.project.md` 생성 (정보 종합)

`plugin/templates/CLAUDE.project.md` 템플릿 기반 + §3 추출 + §4 인덱스 + 다음 정보:

- 서비스명: 폴더 이름 또는 `package.json` `name`
- 사용된 스택: `package.json` `dependencies`에서 핵심만 추출 (Next.js/React/Vue/...)
- 디자인 시스템 토큰: §3에서 추출한 요약 또는 "없음 + 권유 메시지" 표시
- 컴포넌트 인덱스: §4에서 생성
- 인계 주의사항: "외부 데이터 의존 컴포넌트는 `mock/`로 가짜 데이터 박아 미리보기" 안내

이미 `CLAUDE.project.md`가 있으면 **덮어쓰지 않고**, `CLAUDE.project.md.new`로 생성한 뒤 머지 권유:
> 이미 `CLAUDE.project.md`가 있어서 새로 만든 건 `CLAUDE.project.md.new`로 두었어요. 두 파일을 같이 보면서 어떤 부분을 합칠지 같이 정리해볼까요?

### 7.1 `./CLAUDE.md` import 라인 보장 (방어적)

`CLAUDE.project.md`는 비표준 이름이라 새 대화 시작 시 자동 로드 X — 자동 로드되는 `./CLAUDE.md`에 `@CLAUDE.project.md` import 한 줄을 박아둬야 새 대화에서도 디자인 토큰·컴포넌트 인덱스·페르소나 요약이 이어진다. `/kdesigner:디자인초기설정`이 정상 흐름에서 이미 박지만, 사용자가 슬래시 없이 자연어로 `import-existing`을 바로 발동한 경우를 위한 *방어적 보장*.

기존 프로젝트는 *대부분 `./CLAUDE.md`가 이미 있을 가능성*이 높다(개발자가 박아둔 코드베이스 안내 등). 따라서 *백업 정책*을 명확히 한다:

처리 절차:

1. **`Read ./CLAUDE.md`** — 파일 존재·내용 확인.

2. **시작 마커(`<!-- kd:designer-mode:start -->`) 발견** → 스킵(`/kdesigner:디자인초기설정`이 이미 박음).

3. **마커 부재 + 파일 존재** (가장 흔한 경우):
   - `cp ./CLAUDE.md ./CLAUDE.md.kd-backup-<YYYYMMDD-HHmm>` — *반드시 백업 먼저*. 개발자가 박아둔 내용을 잃지 않게.
   - 끝에 빈 줄 + 마커 격리 블록 append:
     ```
     
     <!-- kd:designer-mode:start -->
     @CLAUDE.project.md
     <!-- kd:designer-mode:end -->
     ```
   - 응답에 백업 경로 1줄 노출 — "원래 `CLAUDE.md`는 `./CLAUDE.md.kd-backup-...`에 보관해뒀어요".

4. **파일 부재** (드문 경우 — 정말 빈 프로젝트에 가까움):
   - `touch ./.kd-no-prior-claude-md` 후 `Write ./CLAUDE.md`로 마커 격리 + import 한 줄만.

5. **검증** — 처리 후 마커 쌍이 정확히 1쌍인지 `Read`로 확인. 0·2쌍 이상이면 응답에 경고 1줄.

### 7.2 사이클 시작 시점 기록 (export-handoff용)

기존 git 저장소 가정(import-existing은 빈 디렉토리 X). `export-handoff`가 *이번 사이클에 추가/변경된 파일만* 인계 README에 정리하도록 기준점 SHA를 박아둔다.

처리 절차:

1. `test -f ./.claude/.kd-session-base` — 이미 있으면 **덮어쓰지 X** (`/kdesigner:디자인초기설정`이 먼저 박았으면 그 값 그대로). 처음 박는 1회만 책임.
2. 부재 시:
   - `mkdir -p ./.claude`
   - `echo "$(git rev-parse HEAD)" > ./.claude/.kd-session-base` (저장소 아니면 스킵)
3. **`.gitignore` 처리** — `/kdesigner:디자인초기설정` §4.1과 동일(`.claude/.kd-session-base` 한 줄 자동 추가, 기존 줄 보존, `.gitignore` 자체 부재면 새로 만들기, `.claude/` 디렉토리 자체는 gitignore X).

### 8. 응답 가공 (호출 측 톤)

응답 패턴 (성공):
> **기존 프로젝트 분석** 끝났어요 — 이 프로젝트는 **Next.js + Tailwind + shadcn/ui** 조합으로 만들어져 있고, 공통 디자인 약속(색·둥글기 등)도 잡혀 있어요.
>
> 발견한 컴포넌트 **N개**를 `CLAUDE.project.md`에 정리해뒀어요. 그중 **M개**는 외부 데이터에 의존해서 미리보기 할 때 가짜 데이터(`mock/`)가 필요해요.
>
> 이제 어떤 화면을 먼저 손볼까요?

디자인 시스템 *없음* 분기에서는 §3-B 메시지를 응답 본문에 그대로 노출.

## Subagent 위임
- **이 Skill 자체가 Sonnet Subagent로 동작** (`model: sonnet`) — 코드 스캔 + 컴포넌트 문서화, 중간 난이도 (PRD §12)
- 내부 위임:
  - 컴포넌트 스캔이 50개 넘는 대규모 → *우선순위 추리기*는 메인 모델 판단으로 유지 (Sonnet 직접). 추가 위임 X.
  - `error-translator` (메인 가로채기) — 파일 읽기 실패·인코딩 깨짐 시
- *수정* 책임은 분리 — 인덱스 갱신은 향후 `design-system-guard`가 담당 (CLAUDE.md §컴포넌트 인덱스)

## 응답 톤
- 한국어, 비유 + 용어 한글 병기 (`designer-persona` 글로벌 원칙)
- 기존 코드 훼손 가능성을 *명시적으로 안심시킴* — "기존 파일은 손대지 않았어요" 한 줄
- 디자인 시스템 *없음* 분기에서 부담 안 주기 — "일단 받아서 진행" 길을 항상 열어둠
- 응답 끝 다음 행동 1개 제안 — "어떤 화면을 먼저 손볼까요?" 또는 "첫 화면 한번 띄워볼까요?"

## 의존
- 다른 Skill: `design-system-guard` (이후 인덱스 갱신 위임), `auto-validate` (인계 직전 검증), `preview` (첫 화면), `error-translator` (스캔 실패), `designer-persona` (톤)
- 외부 도구: `Glob`/`Grep` (스캔), `Read` (분석), `Write` (인덱스·`CLAUDE.project.md` 생성), `Edit` (`package.json` scripts 보장 — 충돌 시 X)
- 템플릿: `plugin/templates/CLAUDE.project.md`
- 추적: ROADMAP O-5 (디자인 시스템 *없는* 프로젝트에서 만들어주는 흐름 — 1차 미구현)
- 참조: PRD §5 import-existing, CLAUDE.md §컴포넌트 인덱스
