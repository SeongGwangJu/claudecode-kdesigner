# §1. 기존 상태 진단 (읽기만)

`Glob`/`Read`로 한 번에. **수정 X, 진단 O**.

| 확인 항목 | 도구 | 산출 변수 |
|---|---|---|
| `DESIGN.md` 존재 (`https://getdesign.md/`) | `Glob` + `Read` | `hasDesignMd` |
| `package.json` (스택·매니저·라우터 추론) | `Read` | `pkgManager`, `framework`, `routerHint` |
| `tsconfig.json` 존재 | `Glob` | `hasTs` |
| 디자인 토큰 (`tailwind.config.*`, `app/globals.css`, `styles/globals.css`, `theme/*`, `tokens/*`, `design-system/*`) | `Glob` + `Read` | `hasTailwind`, `hasTokens`, `hasShadcn`(`components.json`) |
| 컴포넌트 디렉토리 (`components/`, `src/components/`) | `Glob` | `hasComponentsDir` |
| **인증·API 흔적** (`middleware*`, `app/api/**`, `pages/api/**`, `auth*`, `lib/auth*`) | `Glob` | `hasAuth`, `hasApiRoutes` |
| **라우트 정의 패턴** (§1.3) | `Glob` | `routePaths` |
| **실행 위치 vs 프로젝트 루트** (§1.4) | `Bash pwd` + `git rev-parse --show-toplevel` | `pwd`, `gitRoot`, `pwdIsRoot` |

## §1.3 라우트 정의 패턴 — 프레임워크 범용 휴리스틱

결정론적 매트릭스 X — *라우트 정의 패턴을 AI가 자율 탐지*. `framework` 추론 후 다음 *참고 데이터*를 보조로 사용:

| 프레임워크 신호 | 라우트 패턴 |
|---|---|
| `next` + `app/` + `app/layout.tsx` | `app/**/page.{tsx,jsx,ts,js}`·`app/**/layout.*`·`app/**/route.*` |
| `next` + `pages/` | `pages/**/*.{tsx,jsx,ts,js}` (단 `pages/api/**`는 §api 분기) |
| `vite` + `react-router*` | `src/routes/**`·`src/router.*` 또는 router 정의 파일 |
| `expo-router` | `app/**/*.{tsx,jsx,ts,js}` |
| `@sveltejs/kit` | `src/routes/**/+page.svelte`·`+layout.svelte` |
| `astro` | `src/pages/**/*.astro` |
| 매치 X | `framework` 미상 → 사용자에게 1회 묻기 또는 컴포넌트 기반만 |

룰: 신호 추론 → 패턴 매치 파일 목록 = `routePaths`. 표에 없는 프레임워크면 *코드 패턴*(`createRouter`/`defineRoutes`/파일 시스템 컨벤션)을 휴리스틱.

## §1.4 실행 위치 vs 프로젝트 루트

`pwd`와 `gitRoot` 비교 3분기:

| 신호 | 분기 | 안내 |
|---|---|---|
| `pwd` == `gitRoot` 또는 git 아님 | 그대로 진행 | "여기서 작업 시작" — 응답 노출 X (정상) |
| `pwd` != `gitRoot`, `pwd`가 `gitRoot` 하위 | `AskUserQuestion` 1회 | "이 폴더는 더 큰 프로젝트의 *하위*예요. — *루트로 이동* / *여기서 떼어내 작업* / 잘 모르겠어요(루트 권장)" |
| 빈 디렉토리 (Glob 파일 0개) | 사용자가 이 Skill에 *들어왔다는 사실 자체*가 기존 코드를 가져올 결이라는 신호. 빈 폴더라는 환경 조건으로 새 디자인 결로 우회 X. 어떤 종류 입력을 옮길 수 있는지(전체/추출분/시스템 단독/일부) 방향만 안내하고 종료. | — |

루트 이동 선택 시: 응답 본문에 *그 경로로 이동해서 다시 부르세요* + 슬래시(`/kdesigner:프로젝트시작`).

## §2. 디자인 시스템 존재 여부 판정

| 조건 | 분류 |
|---|---|
| `hasDesignMd` = true | **있음 (DESIGN.md 1순위)** — §3-A로 가되 DESIGN.md가 단일 진실 |
| `components.json` + `tailwind.config.*` + `globals.css` CSS variables | **있음 (shadcn 류)** |
| 별도 토큰 파일(`theme/*`·`tokens/*`) 명시적 존재 | **있음 (커스텀)** |
| `tailwind.config.*`에 `theme.extend.colors`만 일부 | **부분만 있음** |
| Tailwind도 토큰도 없음 | **없음** |
