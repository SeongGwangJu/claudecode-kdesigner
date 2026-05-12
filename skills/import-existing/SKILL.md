---
description: |
  기존 프로젝트에 디자이너가 안전하게 끼어들기. 입력 종류 자동 분류(전체 레포 / 디자인+페이지 추출분 / 디자인 시스템만 / 컴포넌트 일부) → 분기별 처리. 운영 중인 프론트엔드 레포가 들어오면 *디자인 모드*로 변환 — 인증·API stub을 별도 모듈(`mock/auth-stub.ts`, `mock/api-stubs/`)로 격리해 prod 경계 코드는 손대지 않는다. 페이지 단위까지 인덱싱. 기존 코드 훼손 위험 최소화.

  발동 예시 (사용자 자연어):
  - "기존 프로젝트에서 가져오기", "회사 레포에 끼어들어서 작업하고 싶어"
  - "운영 중인 서비스 받았는데 디자인만 손볼게", "백엔드 없이 일단 화면만 띄워줘"
  - "이미 있는 코드에 디자인 추가", "이 프로젝트에 디자이너 모드 켜줘"
  - "있는 거 분석해서 셋업해줘"

  사용 시점: 빈 디렉토리가 아닌 기존 코드베이스에서 디자이너 작업 시작. `package.json` 또는 `components/` 등 작업 흔적이 있을 때.
model: inherit  # CLAUDE.md §11 — 입력 4분류·디자인 시스템 추출·페이지 변환·격리 모듈 설계가 디자인 컨텍스트 의존 (11-G reframe, 기존 sonnet)
---

## 목적
기존 코드 훼손 위험을 최소화하며 디자이너가 끼어들 수 있는 *단일 참조점*(컴포넌트·페이지 인덱스 + 디자인 시스템 메모 + 변환 결과)을 만든다. *읽기·문서화 중심*, 코드 수정은 폴더 추가(`mock/`, `asset/`)·문서 추가가 기본 — 단 *전체 레포(A 분기)*에 한해 디자인 모드 격리 모듈을 *prod 경계 밖*에서 별도 commit 단위로 박는다(§3-D).

## 발동 조건

### 발동
- "기존 프로젝트에서 가져오기"/"회사 레포 끼어들기"/"운영 레포 받았는데" 류 자연어
- `/kdesigner:프로젝트시작` 직후 비어있지 않은 디렉토리 감지 시 자연 권유
- `new-service` 시작 시 §1 가드에서 기존 작업 흔적 발견 시 권유

### 발동 X
- 완전히 빈 디렉토리 → `new-service` 우선
- 디자인 토큰 *변경* 의도 ("색 좀 바꿔줘") → `design-system-guard`

## 처리 흐름

### §0. 입력 종류 분류 (먼저 결정)

디자이너가 첨부한 *입력의 종류*에 따라 이후 흐름이 갈린다. 진단 신호로 자동 판정 후 `AskUserQuestion`으로 *1회만* 확인.

**자동 판정 신호** (§1 진단과 같은 `Glob`/`Read`로 동시 수집):

| 신호 | A 전체 레포 | B 디자인+페이지 추출분 | C 디자인 시스템만 | D 컴포넌트 일부 |
|---|---|---|---|---|
| `package.json` | 있음 + 라우트 + `api/` 또는 `middleware*` | 있음 (부분) 또는 부재 | 있음 (부분) | 보통 부재 |
| 라우트 정의 (§1.3) | 있음 | 일부 | 없음 | 없음 |
| 컴포넌트 디렉토리 | 있음 (대량) | 있음 | 있음 (UI 베이스) | 단편 |
| `middleware*` / `app/api/**` / `auth*` 흔적 | 있음 | 없음 | 없음 | 없음 |
| 디자인 토큰 (`tailwind.config.*` + `globals.css`) | 있음 | 일부 | 있음 (중심) | 없음 |

판정 우선순위: A(인증·api·라우트 모두 발견 시) > B(라우트 일부) > C(토큰 중심) > D(나머지).

**확인 1회** — 자동 판정 결과를 1회 `AskUserQuestion`으로 확인 (사용자 답 우선):

> 이 프로젝트는 **{{A 전체 레포 / B 디자인+페이지 추출분 / C 디자인 시스템만 / D 컴포넌트 일부}}**로 보여요. 맞으세요?
> - 맞아요 (이 분류로 진행)
> - 다른 종류예요 — {{나머지 3개 항목}}
> - 잘 모르겠어요 → 자동 판정대로 진행

분기 라우팅:

| 분류 | 분기 |
|---|---|
| A 전체 레포 | §1 진단 → §2 디자인 시스템 판정 → §3-A/B/C → **§3-D 운영 레포 변환** → §4 컴포넌트 + §4.5 페이지 → §5/§6/§7 |
| B 디자인+페이지 추출분 | §1 → §2 → §3-A/B/C → §4 + §4.5 (라우트 일부) → §5/§6/§7. *§3-D 스킵* — 인증·API 셋업 없으면 격리 셋업도 필요 X |
| C 디자인 시스템만 | §1 → §2 → §3-A (토큰 추출) → §7 시드 → "이 시스템으로 어떤 화면 만들고 싶으세요?" → `new-service` 합류 권유 |
| D 컴포넌트 일부 | §1 → §4 (단편 인덱싱) → §7 부분 + 한계 안내 1줄 ("hook·라우트 정보가 없어서 미리보기는 제한적이에요") |

### §1. 기존 상태 진단 (읽기만)

`Glob`/`Read`로 한 번에 수집. **수정 X, 진단 O**.

| 확인 항목 | 도구 | 산출 변수 |
|---|---|---|
| `DESIGN.md` 존재 (`https://getdesign.md/` 표준) | `Glob` + `Read` | `hasDesignMd` |
| `package.json` (스택·매니저·라우터 추론) | `Read` | `pkgManager`, `framework`, `routerHint` |
| `tsconfig.json` 존재 | `Glob` | `hasTs` |
| 디자인 토큰 (`tailwind.config.*`, `app/globals.css`, `styles/globals.css`, `theme/*`, `tokens/*`, `design-system/*`) | `Glob` + `Read` | `hasTailwind`, `hasTokens`, `hasShadcn`(`components.json`) |
| 컴포넌트 디렉토리 (`components/`, `src/components/`) | `Glob` | `hasComponentsDir` |
| **인증·API 흔적** (`middleware*`, `app/api/**`, `pages/api/**`, `auth*`, `lib/auth*`) | `Glob` | `hasAuth`, `hasApiRoutes` |
| **라우트 정의 패턴** (§1.3 — 프레임워크 추론 후 결정) | `Glob` | `routePaths` 배열 |
| **실행 위치 vs 프로젝트 루트** (§1.4) | `Bash pwd` + `git rev-parse --show-toplevel` | `pwd`, `gitRoot`, `pwdIsRoot` |

#### §1.3 라우트 정의 패턴 — 프레임워크 범용 휴리스틱

결정론적 매트릭스 X — *라우트 정의 패턴을 AI가 자율 탐지*. `framework` 추론 후 다음 *참고 데이터*를 보조로 사용 (사전 X, 휴리스틱):

| 프레임워크 신호 | 라우트 패턴 (탐지 대상) |
|---|---|
| `next` + `app/` 디렉토리 + `app/layout.tsx` 존재 | `app/**/page.{tsx,jsx,ts,js}`, `app/**/layout.*`, `app/**/route.*` |
| `next` + `pages/` 디렉토리 | `pages/**/*.{tsx,jsx,ts,js}` (단 `pages/api/**`은 §api 분기) |
| `vite` + `react-router*` 의존 | `src/routes/**`, `src/router.*`, 또는 router 정의 파일 |
| `expo-router` 의존 | `app/**/*.{tsx,jsx,ts,js}` |
| `@sveltejs/kit` 의존 | `src/routes/**/+page.svelte`, `src/routes/**/+layout.svelte` |
| `astro` 의존 | `src/pages/**/*.astro` |
| 위 어느 것도 매치 X | `framework` 미상 → 사용자에게 1회 묻기 또는 컴포넌트 기반으로만 진행 |

룰: *프레임워크 신호 추론 → 패턴에 해당하는 파일 목록을 `routePaths`로 수집*. 위 표에 없는 프레임워크면 *코드 패턴*(`createRouter`/`defineRoutes`/파일 시스템 라우팅 컨벤션)을 휴리스틱으로 추론.

#### §1.4 실행 위치 vs 프로젝트 루트 — 자율 판단

`pwd`와 `gitRoot`를 비교해 3분기:

| 신호 | 분기 | 안내 |
|---|---|---|
| `pwd` == `gitRoot` 또는 git 저장소 아님 | 그대로 진행 | "여기서 작업 시작할게요" — 응답 본문 노출 X (정상) |
| `pwd` != `gitRoot`, `pwd`가 `gitRoot` *하위* | `AskUserQuestion` 1회 | "이 폴더는 더 큰 프로젝트의 *하위*예요. 어떻게 시작할까요? — *프로젝트 루트로 이동해 셋업* / *여기서 떼어내 작업* / 잘 모르겠어요(루트 이동 권장)" |
| 완전 빈 디렉토리(`Glob`로 파일 0개에 가까움) | "어디서 가져올까요?" 1회 또는 `new-service` 권유 | — |

루트 이동 선택 시: 응답 본문에 *그 경로로 이동해서 다시 부르세요* 한 줄 + 슬래시 호출 안내(`/kdesigner:프로젝트시작`).

### §2. 디자인 시스템 존재 여부 판정

| 조건 | 분류 |
|---|---|
| `hasDesignMd` = true | **있음 (DESIGN.md 1순위)** — §3-A로 가되 DESIGN.md가 단일 진실 |
| `components.json` + `tailwind.config.*` + `globals.css` CSS variables | **있음 (shadcn 류)** |
| 별도 토큰 파일(`theme/*`, `tokens/*` 등) 명시적 존재 | **있음 (커스텀)** |
| `tailwind.config.*`에 `theme.extend.colors`만 일부, 토큰화 안 됨 | **부분만 있음** |
| Tailwind도 토큰도 없음 | **없음** |

### §3-A. 디자인 시스템 *있음* — 추출·요약

**DESIGN.md 우선** — `hasDesignMd` = true면 *그 파일이 1순위 토큰 소스*. 코드(`tailwind.config`/`globals.css`) 추출은 *보조*. 충돌 시 DESIGN.md가 단일 진실. `CLAUDE.project.md` §디자인 시스템 §철학 슬롯 안내 끝에 `> DESIGN.md를 1순위 소스로 사용 — 토큰·컴포넌트 규약은 그 파일이 단일 진실.` 한 줄 박기(`/프로젝트시작` §2에서 이미 박혔으면 중복 X).

`Read`로 토큰 정의 파일 직접 읽어 `CLAUDE.project.md` §design-tokens에 *요약*. 추출 대상은 색·spacing·radius·typography. 요약 포맷은 `## 핵심 토큰` 슬롯 본문대로 — primary/secondary/neutral 색 N개, `--radius` 기준, 본문 폰트, 정의 위치 한 줄.

> ⚠️ 한계: `tailwind.config.*`이 동적 코드(함수 호출·외부 파일 합치기)면 토큰 추출이 부분만 될 수 있어요. `CLAUDE.project.md` 토큰 섹션을 사용자가 1회 다듬어주시면 가장 정확.

추출은 *프로젝트 미학 슬롯에도 시드* — 추출한 폰트가 한글 친화(Pretendard/Spoqa/SUIT 등)면 §철학·§톤 후보 한 줄. dominant 색·둥글기 결을 §철학 1줄 후보로. §피하고 싶은 디자인은 글로벌 미학 학습 §avoidance가 누적되어 있으면 거기서 시드(§7). 비어있는 차원은 *여기서 묻지 X* — `aesthetic-guard`가 첫 작업 시 자연스레 1개씩.

### §3-B. 디자인 시스템 *없음* — 만들기 권유 (메시지만)

PRD §10 위험 + ROADMAP O-5: **1차에선 권유 메시지만**. 자동 생성 X.

응답 패턴:
> 이 프로젝트는 **공통 디자인 약속**(`design system`)이 아직 정해져 있지 않은 것 같아요. 색·간격·둥글기 같은 공통 기준이 없으면 화면마다 따로 놀게 돼요.
>
> 두 가지 길:
> - **개발자에게 요청** — 가장 안전해요. "어떤 색·둥글기·간격을 기준으로 쓸지 정해주세요"라고 부탁
> - **지금 일단 만들어 보기** — 가능은 한데, 나중에 개발자 기준과 충돌 가능 (지금 만드는 흐름은 다음 버전에서 추가될 예정)
>
> 일단은 **있는 그대로 받아서 진행**할 수 있어요 — 컴포넌트만 정리해드릴게요.

§4로 이어감. 만들기 자동 흐름은 ROADMAP O-5 추적, 1차 미구현. 미학 컨텍스트는 *빈 슬롯*으로 두고 `aesthetic-guard`가 첫 작업 시 자연스레 채움.

### §3-C. *부분만 있음* — 정리 권유

§3-A처럼 추출하되, 응답에 "토큰화가 일부만 되어 있어서 새 화면 만들 때 일관성이 흔들릴 수 있어요" 한 줄 첨부.

### §3-D. 운영 레포 → 디자인 레포 변환 (A 분기 전용)

§0에서 A로 판정된 경우만 실행. 핵심 원칙: ***prod 경계 코드(`middleware*`, `app/api/**`, `lib/**`, `hooks/**`, `stores/**`)는 절대 분기를 박지 X***. 인증·API 우회는 *별도 모듈에 격리*해 컴포넌트 *import 경로 차원에서만* 분기. 변경은 *별도 commit 단위*로 — 디자이너가 나중에 본 레포에 반영할 때 rebase·revert 쉽게.

처리 절차 (각 단계 별도 commit 권장 — 직접 commit은 §7 뒤 `safe-save` 위임 시점):

1. **인증 stub 모듈** — `mock/auth-stub.ts` 생성. 진단된 인증 훅(`useAuth`/`useSession`/`useUser` 등 — §4.2에서 발견)의 mock 버전. 반환 형태는 *실제 훅의 타입 시그니처를 따라간다*(`Read` 해서 추론). 기본 mock 사용자 1명, `loading: false`, `error: null`.

2. **API stub 모듈** — `mock/api-stubs/` 디렉토리 생성. `hasApiRoutes` = true일 때 `app/api/**` 또는 `pages/api/**` 라우트별로 mock 응답 파일(`<route-name>.ts`). 실제 라우트의 응답 타입을 알 수 없으면 `{}` 또는 `[]` 빈 응답 + 주석으로 *실 API 응답 구조 추정 필요* 표시.

3. **디자인 모드 토글** — 프레임워크별 환경변수 컨벤션 따름 (휴리스틱):

   | 프레임워크 | 토글 변수 |
   |---|---|
   | Next.js | `NEXT_PUBLIC_KD_DESIGN_MODE === '1'` |
   | Vite | `import.meta.env.VITE_KD_DESIGN_MODE === '1'` |
   | Expo | `process.env.EXPO_PUBLIC_KD_DESIGN_MODE === '1'` |
   | 그 외 | `process.env.KD_DESIGN_MODE === '1'` (커스텀 빌드 시 read 보장 필요 — 응답에 안내 1줄) |

   `lib/design-mode/index.ts` (또는 `src/lib/design-mode/index.ts`) 신규 — `IS_DESIGN_MODE` 상수만 export. **이 모듈은 *디자인 모드 전용*이고, 이 디렉토리 안 코드는 가드 허용 범위** — `publishing-guard` Skill + hook이 `CLAUDE.project.md` §publishing-boundary 슬롯을 통해 *prod 경계 코드 변경*을 자동 차단·동의 흐름·인계 큐 push까지 책임 (Phase 11-C).

4. **환경변수 파일** — `.env.kdesigner-design` 생성. 토글 변수 = `1` 한 줄만. `.gitignore`에 *추가 X* — *commit해 디자이너 환경에서 그대로 작동*. prod `.env*`는 *건드리지 X*.

5. **`package.json` scripts 추가** — `dev:kd-design` (기존 `dev` 명령 앞에 환경변수 export. 매니저별로):
   - npm/pnpm: `dotenv -e .env.kdesigner-design -- <기존 dev 명령>` 또는 OS 분기 `<env_var>=1 <기존 dev>`
   - 안전한 fallback: `cross-env <var>=1 <기존 dev>` (cross-env 의존성 추가는 *AskUserQuestion 1회*로 동의)

6. **prod 코드는 *손대지 X*** — 컴포넌트에서 인증·데이터 훅을 import하는 줄을 *명시 동의 후* 다음 패턴으로 변환:
   ```ts
   // 기존: import { useAuth } from '@/hooks/useAuth'
   // 변환:
   import { useAuth as useAuthProd } from '@/hooks/useAuth'
   import { useAuth as useAuthStub } from '@/mock/auth-stub'
   import { IS_DESIGN_MODE } from '@/lib/design-mode'
   const useAuth = IS_DESIGN_MODE ? useAuthStub : useAuthProd
   ```
   → 변환 *전*에 `AskUserQuestion` ("이 컴포넌트가 인증 훅을 직접 호출해요. 디자인 모드에서 mock으로 분기할까요?"). 변환은 *컴포넌트 단위*로, *대량 일괄 변경 X*. 디자이너가 만질 페이지부터.

7. **변경 *별도 commit*** — §7 끝나고 `safe-save` 위임 시 commit 메시지: *"디자인 모드 변환 — 인증·API stub 격리(`lib/design-mode/`·`mock/auth-stub.ts`·`mock/api-stubs/`), `dev:kd-design` 추가"*. 이후 컴포넌트 분기 변경은 *다음 commit*에서.

8. **결과 기록** — `CLAUDE.project.md` §design-mode-config 슬롯에 박기 (§7 참조). §publishing-boundary 슬롯은 *템플릿 기본값 그대로* 두기(빈 골격) — 사용자/개발자가 본 레포 구조 보고 수정 가능. 기본값은 hook이 직접 적용하므로 비어있어도 가드 동작.

### §4. 컴포넌트 스캔 + 인덱스 첫 생성

이 Skill의 *핵심 산출물 1*. `CLAUDE.project.md` §components 슬롯에 일괄 생성.

#### §4.1 발견
`Glob`으로 `components/**/*.{tsx,jsx}`, `src/components/**/*.{tsx,jsx}`, `app/**/*.{tsx,jsx}` 중 컴포넌트 패턴(default export + PascalCase) 모두 수집. **50개 상한** — 넘으면 `components/ui/*` 같은 디자인 시스템 베이스 우선, 나머지는 "..." + 사용자 안내.

#### §4.2 분석 & 인덱스 라인
파일 단위 `Read` → 이름·경로·핵심 props(1~3개)·variant(`variant`/`size`/`color` union)·의존 hook(`use*`) 추출. 형식 (CLAUDE.md §컴포넌트 인덱스):

```
- `Button` · `components/ui/Button.tsx` · `variant: primary|secondary|ghost`, `size: sm|md|lg` · 기본 액션 버튼
- `UserAvatar` · `components/UserAvatar.tsx` · `size: sm|md`, `useAuth()` 의존 · 로그인한 사용자 표시
```

#### §4.3 외부 데이터 의존 컴포넌트
외부 데이터 hook(`useAuth`/`useQuery`/`useSession`/`useSWR`/`fetch` 등)에 의존하면 *디자이너 더미 환경에서 깨질 위험* → `CLAUDE.project.md` §외부 데이터 의존 컴포넌트 별도 섹션에 ⚠️ 표시 + mock 활용 안내:

```markdown
## 외부 데이터 의존 컴포넌트 (더미 환경 주의)
- `UserAvatar` — `useAuth()` 의존. 미리보기 하려면 `mock/auth.ts`에 가짜 사용자 박아두는 게 안전.
```

A 분기(§3-D 적용)면 이 섹션의 컴포넌트들이 *§3-D §6 변환 후보* — 디자이너 첫 작업 시 자연 권유.

### §4.5 페이지 단위 스캔 + 인덱싱

이 Skill의 *핵심 산출물 2*. §1.3에서 수집한 `routePaths`를 *디자이너 친화 인덱스*로 가공 → `CLAUDE.project.md` §pages 슬롯에 박기.

#### §4.5.1 페이지 파일 분석
`routePaths` 각 항목 `Read` → 다음 추출:

| 추출 항목 | 추출 방법 |
|---|---|
| 페이지 이름 | 파일 경로에서 추론 — `app/dashboard/page.tsx` → "대시보드" (영어 segment는 그대로 또는 한국어 추정) |
| 라우트 경로 | 프레임워크 컨벤션으로 역산 — Next App: `app/[lang]/cafe/page.tsx` → `/[lang]/cafe`, Pages: `pages/about.tsx` → `/about` |
| 역할 1줄 | 페이지 본문에서 추론 — 제목·헤더·주요 컴포넌트로 한국어 1줄 |
| 외부 데이터 의존 | §4.3 컴포넌트 사용 여부 + 직접 fetch 호출 여부 |

**50개 상한** 동일. 동적 라우트(`[id]`, `[...slug]`)는 그대로 노출 + "동적 경로" 표기.

#### §4.5.2 인덱스 라인 형식

```
- `대시보드` · `app/dashboard/page.tsx` · `/dashboard` · 로그인 후 첫 화면, 카드 3개
- `프로필` · `app/[lang]/profile/page.tsx` · `/[lang]/profile` (동적) · 사용자 설정 · `useAuth()` 의존
```

페이지 단위는 *디자이너 미리보기·작업 진입점* — `preview` Skill이 dev 서버 띄울 때 이 인덱스로 *어디부터 볼까* 권유.

### §5. 디자이너 폴더 규약 추가

기존 폴더 *건드리지 않고* 누락만:

| 폴더 | 동작 |
|---|---|
| `asset/` | 없으면 `.gitkeep` 생성. `public/`·`assets/` 있으면 그쪽으로 통일 안내 |
| `mock/` | 없으면 `.gitkeep` 생성. A 분기면 §3-D에서 이미 채워짐. `__mocks__/`·`fixtures/` 있으면 통일 안내 |
| `components/` | 이미 있음 가정 (없으면 *프로젝트 자체 의심* — 진행 중단) |

### §6. `package.json` scripts 보장

`auto-validate` 표준 키 점검:

| 키 | 부재 시 동작 |
|---|---|
| `lint` | 사용자에게 묻고 추가 (이미 lint 도구 결정되어 있을 수 있음) |
| `typecheck` | 없으면 `tsc --noEmit` 추가 (단, `tsconfig.json` 있을 때만) |
| `dev:kd-design` | A 분기 §3-D에서 추가됨 (B/C/D 분기엔 추가 X) |

기존 scripts와 충돌하면 **묻지 말고 건드리지 X** — 위험 회피. 응답에 "lint/typecheck 명령이 표준이 아니어서 자동 검증이 일부 제한될 수 있어요" 한 줄 첨부.

### §7. `CLAUDE.project.md` 생성 (정보 종합)

`plugin/templates/CLAUDE.project.md` 템플릿 기반 + §3 추출 + §4 컴포넌트 + §4.5 페이지 + §3-D 결과:

- 서비스명: 폴더 이름 또는 `package.json` `name`
- 사용된 스택: `package.json` `dependencies` 핵심만 (Next.js/React/Vue/...)
- 디자인 시스템 토큰: §3 추출 요약 또는 "없음 + 권유 메시지"
- §components 슬롯: §4 인덱스
- §pages 슬롯 (NEW): §4.5 인덱스
- §source-repo 슬롯 (NEW): A 분기일 때 `git remote -v`로 원본 URL 추출 + 현재 branch + 진단 시점 SHA(`git rev-parse HEAD`). F2-#4 `design-sync` 후속에서 사용. 비 git 저장소면 *비워둠*.
- §design-mode-config 슬롯 (NEW): A 분기 §3-D 결과 — 토글 변수명, mock 격리 경로, `dev:kd-design` 스크립트명 한 줄씩.
- 인계 주의사항: "외부 데이터 의존 컴포넌트는 `mock/`로 가짜 데이터 박아 미리보기" 안내

**글로벌 미학 학습 시드** — `~/.claude/CLAUDE.md` §미학 학습의 자동 누적 슬롯이 채워져 있으면, 코드에서 *추출 불가능한 차원*만 시드: §피하고 싶은 디자인 ← 글로벌 §avoidance / §톤 ← 글로벌 §tone-extracted 후보, *코드 추출 톤과 충돌하면 코드 추출 우선* (프로젝트 사실이 우선). 전역이 비어 있거나 없으면 시드 X — `aesthetic-guard`가 첫 작업 시 자연스레.

이미 `CLAUDE.project.md`가 있으면 **덮어쓰지 X** — `CLAUDE.project.md.new`로 생성 + 머지 권유 응답.

#### §7.1 `./CLAUDE.md` import 라인 보장 (방어적)

`CLAUDE.project.md`는 비표준 이름이라 새 대화 시작 시 자동 로드 X — 자동 로드되는 `./CLAUDE.md`에 `@CLAUDE.project.md` import 한 줄. `/kdesigner:프로젝트시작`이 정상 흐름에서 박지만, 사용자가 슬래시 없이 `import-existing`을 자연어로 바로 발동한 경우를 위한 *방어적 보장*. `hasDesignMd`면 `@DESIGN.md`도 같은 마커 블록에.

기존 프로젝트는 *대부분 `./CLAUDE.md`가 이미 있을 가능성* 높음 — *백업 정책* 명확히:

1. `Read ./CLAUDE.md` — 존재·내용 확인.
2. 시작 마커(`<!-- kd:designer-mode:start -->`) 발견 → 스킵.
3. 마커 부재 + 파일 존재:
   - `cp ./CLAUDE.md ./CLAUDE.md.kd-backup-<YYYYMMDD-HHmm>` *반드시 백업 먼저*.
   - 빈 줄 + 마커 격리 블록 append. `hasDesignMd`면 `@DESIGN.md` 한 줄 추가:
     ```
     <!-- kd:designer-mode:start -->
     @DESIGN.md
     @CLAUDE.project.md
     <!-- kd:designer-mode:end -->
     ```
   - 응답에 백업 경로 1줄 노출.
4. 파일 부재: `touch ./.kd-no-prior-claude-md` 후 `Write ./CLAUDE.md`로 마커 격리 + import 라인.
5. 검증: 마커 쌍 정확히 1쌍. 0·2쌍 이상이면 경고 1줄.

#### §7.2 사이클 시작 시점 기록 (export-handoff용)

`export-handoff`가 *이번 사이클 추가/변경 파일만* 인계 README에 정리할 기준점 SHA.

1. `test -f ./.claude/.kd-session-base` — 이미 있으면 **덮어쓰지 X** (`/kdesigner:프로젝트시작`이 먼저 박았으면 그대로).
2. 부재 시: `mkdir -p ./.claude && echo "$(git rev-parse HEAD)" > ./.claude/.kd-session-base` (저장소 아니면 스킵)
3. `.gitignore` — `/kdesigner:프로젝트시작` §4와 동일 처리.

### §8. 응답 가공 (분기별 톤)

A 분기 성공:
> **운영 레포 변환** 끝났어요 — **Next.js + Tailwind + shadcn/ui** 조합, 인증·API는 *별도 모듈로 격리*했어요(`mock/auth-stub.ts`, `mock/api-stubs/`, `lib/design-mode/`). 운영 코드는 *손대지 않았어요*.
>
> 발견한 컴포넌트 **N개** + 페이지 **M개**를 `CLAUDE.project.md`에 정리했고, 그중 **K개** 컴포넌트는 외부 데이터에 의존해서 미리보기 시 mock이 필요.
>
> 디자인 모드로 한 번 켜보시려면 `pnpm dev:kd-design` (또는 npm) — 어떤 화면 먼저 손볼까요?

B/C/D 분기 성공은 §3-B/§3-A 결과 본문 + 다음 행동 1개 ("어떤 화면부터?" 또는 "새 화면 만들어볼까요?")로 마무리.

디자인 시스템 *없음* 분기에서는 §3-B 메시지를 응답 본문에 그대로.

## Subagent 위임
- **이 Skill 자체는 메인 모델 컨텍스트** (`model: inherit` — 11-G reframe, CLAUDE.md §11). 입력 4분류·디자인 시스템 추출·페이지 변환·격리 모듈 설계·컴포넌트 우선순위 결정은 *디자인 퀄리티 영향*이라 다운그레이드 위험. (a) 병렬화 X / (b) 격리 △(일부 정형) / (c) 정형 도구 △ — 어느 사유도 명확 충족 X면 inherit 기본
- 내부 위임:
  - `error-translator` (메인 가로채기) — 파일 읽기·인코딩 실패 시
- *수정* 책임 분리 — 인덱스 갱신은 `design-system-guard`, prod 경계 가드는 `publishing-guard`(Phase 11-C 완비, `CLAUDE.project.md` §publishing-boundary 슬롯 기반 프로젝트별 조정 가능)

## 응답 톤
- 한국어, 비유 + 용어 한글 병기 (`designer-persona`)
- 기존 코드 훼손 *명시적 안심* — "기존 파일은 손대지 않았어요" 한 줄 (A 분기는 *prod 경계 코드*에 한정)
- 디자인 시스템 *없음* 분기에서 부담 안 주기 — "일단 받아서 진행" 길 열어둠
- A 분기 응답에 *별도 commit 단위* 언급 — 디자이너가 본 레포 반영 시 안전
- 응답 끝 다음 행동 1개 + 자연어 1개 (글로벌 §7) — "첫 화면 한번 띄워볼까요? '**보여줘**' 한 마디면 돼요" 류

## 의존
- 다른 Skill: `design-system-guard`(인덱스 갱신 위임), `auto-validate`(인계 직전 검증), `preview`(첫 화면), `error-translator`(스캔 실패), `designer-persona`(톤), `publishing-guard`(A 분기 후 prod 경계 가드 — Phase 11-C 완료), `design-sync`(F2-#4, 11-F 예정)
- 외부 도구: `Glob`/`Grep`/`Read`/`Write`/`Edit`/`Bash`(`git`/`pwd`/`cp`/`mkdir`/`touch`/`echo`)/`AskUserQuestion`
- 템플릿: `plugin/templates/CLAUDE.project.md` (새 슬롯 `source-repo`/`pages`/`design-mode-config` 포함)
- 추적: ROADMAP O-5(디자인 시스템 없는 프로젝트에서 만드는 흐름 — 1차 미구현), Phase 11-B(이 변경), 11-C(가드 연동), 11-F(sync 연동)
- 참조: PRD §5 import-existing 4분류, §10 위험 운영 레포 변환 격리 원칙, CLAUDE.md §컴포넌트 인덱스
