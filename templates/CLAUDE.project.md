# {{서비스명}} — 프로젝트 컨텍스트

> 이 파일은 디자이너가 만드는 *각 프로젝트 루트*에 생성됩니다.
> `/kdesigner:디자인초기설정` 시 placeholder(`{{...}}`)가 사용자 답변으로 채워집니다.
>
> **이 파일은 "이 프로젝트의 사실".** "어떻게 행동할까"는 전역 `~/.claude/CLAUDE.md` (또는 이 파일 끝의 페르소나 요약).

---

## 서비스 한 줄
{{서비스명}} — {{한 줄 목적·핵심 사용자층}}

예: "**다정한 동네 카페 안내** — 30대 직장인이 점심시간 5분 안에 주변 조용한 카페 찾는 모바일 웹"

## 디자인 시스템

> 프로젝트 루트에 `DESIGN.md`(`https://getdesign.md/` 표준)가 있으면 *1순위 토큰 소스*로 자동 인식돼요. `/kdesigner:프로젝트시작`이 발견하면 `./CLAUDE.md`에 `@DESIGN.md` import 라인을 자동으로 박고, `aesthetic-guard`/`design-system-guard`도 그 파일을 단일 진실로 참조.
>
> DESIGN.md 갱신은 플러그인 책임 X — 사용자가 직접 갱신.

<!-- kd:slot:design-philosophy -->
### 철학
{{이 디자인이 추구하는 톤·결을 1~3줄}}

예: "차분하고 미니멀. 둥글기는 작게, 색은 채도 낮게. 정보 우선, 장식 최소."

<!-- kd:slot:project-tone -->
### 톤 한 단어
{{미니멀 / 브루탈 / 에디토리얼 / 플레이풀 / 럭셔리 / 레트로 / 산업적 / 따뜻함 / ...}}

> `aesthetic-guard`가 한 방향 commit 결정에 *제일 먼저 읽는* 슬롯.

<!-- kd:slot:project-references -->
### 레퍼런스
> 이 프로젝트가 *닮고 싶은* 화면·프로덕트 1-3개. 글로벌 디자이너 프로필이 있으면 거기서 시드되고, 이 프로젝트만의 톤이 다르면 여기 따로 적기.

- {{레퍼런스 1}} — {{왜 닮고 싶은지}}
- {{레퍼런스 2}} — {{왜 닮고 싶은지}}

<!-- kd:slot:project-avoidance -->
### 피하고 싶은 디자인 (이 프로젝트 한정)
> 글로벌 회피와 별개로 *이 서비스에서 절대 안 쓰는 것*. 작업 마무리 시 `aesthetic-guard`가 능동적으로 가볍게 묻고, 같은 결이 2회+ 반복되면 전역으로 승격 권유.

- {{회피 1}}
- {{회피 2}}

<!-- kd:slot:design-tokens -->
### 핵심 토큰
- **색**:
  - primary: {{#000000}}
  - secondary: {{#666666}}
  - neutral: {{#FFFFFF / #F5F5F5 / #E0E0E0 / ...}}
- **간격**: {{4 / 8 / 16 / 24 / 32 (px)}}
- **둥글기**: {{0 / 4 / 8 / 12 (px)}}
- **타이포**: {{heading 24/32 · body 16/24 · caption 12/16 (size/line-height)}}

> 토큰 값이 비어 있으면 `design-system-guard` Skill이 첫 사용 시 사용자에게 묻고 채웁니다.

<!-- kd:slot:tech-stack -->
## 사용 스택
- **{{웹/앱}}**: {{Next.js + Tailwind + shadcn/ui + TypeScript}} 또는 {{React Native (Expo) + NativeWind}}
- **아이콘**: {{lucide-react}}
- **더미 데이터 위치**: `mock/`

<!-- kd:slot:source-repo -->
## 원본 레포 (자동 관리)
> 이 섹션은 `import-existing` Skill이 전체 레포(A 분기) 가져올 때 자동 채워요. `design-sync` Skill이 본 레포 갱신분 가져올 때 *마지막 sync* 갱신.
> 비 git 저장소거나 원본이 없으면 비워둠.

- **원본 URL**: {{없음 / git@github.com:org/repo.git 또는 https://...}}
- **branch**: {{main}}
- **진단 시점 SHA**: {{없음 / abc1234}}
- **마지막 sync 시점**: {{없음 / 2026-05-12 14:30, SHA `def5678`}}

<!-- kd:slot:design-mode-config -->
## 디자인 모드 설정 (자동 관리)
> 이 섹션은 `import-existing` Skill이 *운영 레포 변환(A 분기, §3-D)* 시 자동 채워요. 운영 레포 변환을 안 했으면 비워둠.
> 변환 핵심: prod 경계 코드(`middleware*`/`app/api/**`/`lib/**` 등)는 손대지 않고, 인증·API stub을 *별도 모듈*에 격리해 *컴포넌트 import 경로 차원에서만* 분기.

- **토글 변수**: {{없음 / NEXT_PUBLIC_KD_DESIGN_MODE / VITE_KD_DESIGN_MODE / EXPO_PUBLIC_KD_DESIGN_MODE / KD_DESIGN_MODE}}
- **mock 격리 경로**: {{없음 / mock/auth-stub.ts, mock/api-stubs/, lib/design-mode/}}
- **dev 스크립트**: {{없음 / pnpm dev:kd-design}}
- **환경변수 파일**: {{없음 / .env.kdesigner-design (commit됨, prod .env*과 분리)}}

<!-- kd:slot:share-policy -->
## 공유 정책 (자동 관리)
> 이 섹션은 `external-share` Skill이 첫 외부 공유 시 묻고 자동 갱신해요. 사용자가 직접 손대지 마세요.

- **회사 프로젝트 여부**: {{미답변 / 예 / 아니오}}
- **회사명 키워드** (민감정보 스캔용): {{없음 / 키워드 목록}}
- **외부 도구 동의 이력**: {{없음 / 도구명 (날짜)}}

<!-- kd:slot:publishing-boundary -->
## 디자이너 작업 영역 경계 (개발자가 조정)
> 이 섹션은 `publishing-guard` Skill의 *경계 정의*입니다 — 디자이너가 어디까지 손대도 안전한지를 *프로젝트별로* 표현해요.
> `import-existing`이 A 분기(전체 레포 변환)에서 프레임워크 휴리스틱으로 기본값을 시드해요. 본 레포 구조가 다르면 *개발자가 직접 조정*해주세요.
> 비어있으면 hook이 Next.js 기준 기본값(README "디자이너가 안전하게 작업할 영역" 표)을 적용합니다.

### 허용 (디자이너가 자유롭게 손대도 OK)
- `mock/**`
- `lib/design-mode/**` (또는 `src/lib/design-mode/**`)
- `asset/**`, `public/**`, `assets/**`
- `components/**` (단 *props 시그니처 변경*은 가드가 동의 요청)
- `app/**/*.{tsx,jsx}`, `pages/**/*.{tsx,jsx}` (단 `*/api/**` 제외)
- `app/globals.css`, `styles/**`, `**/*.module.css`, `tailwind.config.*`
- `.env.kdesigner-design`

### 금지 (개발자 영역 — 가드가 PreToolUse에서 차단 + 동의 흐름)
- `middleware.*` (요청 가로채기 영역)
- `app/api/**`, `pages/api/**` (API 라우트, `api/mock/**` 제외)
- `lib/**` (런타임 로직, `lib/design-mode/**` 제외)
- `hooks/**` (커스텀 훅 데이터 흐름)
- `stores/**`, `store/**` (전역 상태)
- `config/navigation*`, `config/routes*` (라우팅 메타)
- `package.json`, `tsconfig.*`, `.gitignore`, `.npmrc`, `.nvmrc`
- `.env`, `.env.*` (`.env.kdesigner-design` 제외)

### 패턴 가드 (디자이너 영역 *안*이라도 PostToolUse가 잡는 변경)
- `interface ...Props` 또는 `type ...Props =` 줄 변경 — *컴포넌트 사용법*이 바뀜
- `@/hooks`·`@/stores`·`@/lib/api` 새 import — *도메인 결합*
- `useState`/`useEffect`/`useCallback`/`useMemo`/`useReducer` 신규 호출 — *데이터 흐름 추가*
- `<Link>` 제거 — *접근성 회귀 가능*
- 함수 본문 5+ 라인 동시 추가·제거 — *알고리즘 교체 가능성*

> 위 패턴이 감지되면 `publishing-guard`가 (a) 격리 OK / (b) 격리 부족 / (c) 진짜 prod 영향 3분류로 톤 차별화해 안내해요. (c) + 명시 동의 시 다음 인계 회차 `HANDOFF.md`의 *⚠️ 디자인 외 변경 — 검토 필요* 섹션에 자동 기록.

## 폴더 규약
- `asset/` — 이미지·아이콘·폰트 등 시각 자산
- `mock/` — 더미 데이터 (가짜 텍스트·숫자·리스트)
- `components/` — 재사용 컴포넌트

자연어 "이 이미지 추가해줘" → 자동으로 `asset/`에 저장 + 컴포넌트에서 참조.

<!-- kd:slot:components -->
## 사용 가능한 컴포넌트

> 이 섹션은 *자동 관리*됩니다. 사용자가 직접 손대지 마세요.
> - 첫 생성: `import-existing` Skill (기존 프로젝트 가져올 때 일괄)
> - 갱신: `design-system-guard` Skill (신규/변경 컴포넌트 감지 시)

| 이름 | 경로 | 핵심 props | variant |
|---|---|---|---|
| {{Button}} | {{components/Button.tsx}} | {{variant, size, disabled}} | {{primary / secondary / ghost}} |

<!-- kd:slot:pages -->
## 사용 가능한 페이지

> 이 섹션은 *자동 관리*됩니다.
> - 첫 생성: `import-existing` Skill §4.5 (라우트 정의 패턴 자동 탐지 — Next.js App/Pages, Vite+React Router, Expo, SvelteKit, Astro 등 프레임워크별 휴리스틱)
> - 갱신: 신규 페이지 감지 시 `design-system-guard`가 자동 (계획)

| 이름 | 파일 경로 | 라우트 | 역할 1줄 |
|---|---|---|---|
| {{대시보드}} | {{app/dashboard/page.tsx}} | {{/dashboard}} | {{로그인 후 첫 화면}} |

## 더미 데이터 규칙
- 모든 가짜 데이터는 `mock/` 폴더에 분리
- 컴포넌트 안에 *하드코딩 X* — 컴포넌트는 props로 받기만
- 실제 API 응답 형식과 일치하게 (개발자 인계 시 `mock/` → 실제 fetch만 갈아끼우면 되도록)

예: `mock/cafes.ts`가 `[{ id, name, address, isQuiet }]` 형식이면, 실서비스 API도 같은 형식이어야 함.

## 인계 주의사항

| 영역 | 누가 | 무엇 |
|---|---|---|
| `mock/` | 디자이너 | 가짜 데이터 — 개발자가 실제 API로 교체 |
| `asset/` | 디자이너 | 이미지·아이콘·폰트 — 그대로 사용 |
| `components/` | 디자이너 | 재사용 컴포넌트 — 디자이너 영역, 개발자는 그대로 받음 |
| API 라우트 | 개발자 | 백엔드 연결 |
| 인증·권한 | 개발자 | 로그인·세션 |
| DB 스키마 | 개발자 | 실제 데이터 저장 |

핸드오프는 `export-handoff` Skill("개발자한테 넘기기" 발화)이 자동 정리.

<!-- kd:slot:share-history -->
## 공유 이력
> 이 섹션은 `external-share` Skill이 자동 갱신해요. 인계 시 `export-handoff`가 참조해서 개발자에게 *이 디자인이 누구에게 언제 공유됐는지* 맥락을 함께 전달.

| 일자 | 분류 | 대상 | URL | 상태 |
|---|---|---|---|---|
<!-- 예: | 2026-04-29 17:32 | B 단기 | 클라이언트 1차 시안 | https://... | 활성 (`abc1234`) | -->

<!-- kd:slot:last-work -->
## 마지막 작업
> 이 섹션은 `fresh-session-guide` Skill이 자동 갱신해요. 새 대화 시작 시 "이어서 작업하자"의 단서로 쓰여요.

---

## 페르소나 요약 (전역 설정 *안 한* 사용자용 단독 동작 가드)

> 사용자가 `/kdesigner:디자인초기설정` 시 *전역 추가를 거부*했더라도 이 프로젝트 안에서는 디자이너 모드가 작동하도록, 페르소나의 핵심을 여기 요약합니다.
> 자세한 페르소나는 전역 `~/.claude/CLAUDE.md` (전역 설정한 경우에만 존재).

- 사용자는 한국 디자이너 — Figma 능숙, git/터미널 미숙
- **응답은 한국어로**. 영어 단독 노출 X
- **용어 한글 병기**: **한국어 의미** (`영어 원문`) — 변경 영향 1줄 패턴
- **디자인 일반 용어**(컴포넌트·자산·토큰·반응형)는 풀어 설명 X — 디자이너가 이미 아는 영역
- **추상화는 git/터미널/프레임워크 용어에만**: `commit`, `push`, `npm install`, `port` 등
- **모든 되돌림은 `git revert`**. `reset --hard` / `push --force` 절대 자동 실행 X
- **에러는 자동 회복 우선**: 의존성 누락 → 자동 설치, 포트 충돌 → 다른 포트, 영어 스택트레이스 본문 노출 X (코드 블록 격리)
- **결정 피로 최소화**: 한 사이클 질문 3회 상한, 모든 객관식에 "잘 모르겠어요 / 추천해주세요" 옵션
- **응답 끝 다음 행동 1개**: "이제 ~~하시겠어요?" — 정확히 1개, 0개도 2개도 X
- **위험 동작은 명시 동의**: 전역 CLAUDE.md 수정, 사용자 디렉토리 외부 변경, `git revert`, `git push`, 의존성 *제거*

기본 추천 스택: 웹 = Tailwind + shadcn/ui + Next.js + TypeScript / 앱 = Expo + NativeWind / 아이콘 = lucide-react.
