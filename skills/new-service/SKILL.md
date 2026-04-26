---
description: |
  새 서비스 0→1 셋업. 빈 디렉토리에서 웹/앱 묻고 기본 추천 스택(웹: Tailwind+shadcn/ui+Next.js+TypeScript / 앱: Expo+NativeWind)으로 폴더 구조(`asset/`, `mock/`, `components/`) 생성, `CLAUDE.project.md` placeholder 채워넣기, `package.json` scripts에 `lint`/`typecheck` 보장. 셋업 후 첫 화면을 띄울 수 있는 상태까지 만든다.

  발동 예시 (사용자 자연어):
  - "새 디자인 시작할게", "새로 만들고 싶어"
  - "처음부터 만들어줘", "빈 곳에서 시작"
  - "프로젝트 새로 셋업해줘"

  사용 시점: 빈 디렉토리 또는 명시적으로 "새로 시작" 의도가 있을 때. 기존 코드가 이미 있으면 `import-existing`이 우선.
model: sonnet
---

## 목적
30분 안에 새 서비스 0→1 셋업을 끝내고, 디자이너가 *첫 화면을 만들 수 있는 상태*까지 도달시킨다. 결정 피로 최소화(기본 추천 우선), `auto-validate`가 호출할 표준 scripts 박기까지 이 Skill의 책임.

## 발동 조건

### 발동
- "새 디자인 시작"/"새로 만들고 싶어"/"처음부터 만들어줘" 류 자연어
- `/kd:디자인초기설정` 직후 빈 디렉토리 감지 시 자연 권유

### 발동 X
- 기존 코드가 이미 있는 디렉토리 (`package.json` 또는 `components/` 존재) → `import-existing` 우선
- 슬래시 `/kd:디자인초기설정`은 *모드 켜기*만 담당 — 실제 셋업은 이 Skill

## 처리 흐름

### 1. 빈 디렉토리 확인
첫 단계로 위험 회피 — 기존 작업 덮어쓰기 방지.

| 상태 | 동작 |
|---|---|
| 완전히 빈 디렉토리 | 진행 |
| `.git`만 있음 | 진행 |
| `package.json` 또는 `components/` 존재 | **중단** + `import-existing` 권유 응답 |
| `CLAUDE.project.md` 이미 존재 | **중단** + "이미 셋업되어 있어요" 안내 |

중단 응답 패턴:
> 이 폴더에 이미 작업한 흔적이 있어 보여요(`package.json` 발견). 새로 시작하면 기존 작업이 덮일 수 있어서, **기존 프로젝트 가져오기** 흐름이 더 안전해요. 그쪽으로 진행할까요?

### 2. 핵심 1문 — 웹/앱 (질문 1/3)

`AskUserQuestion`으로 묻는다. 결정 피로 최소화(CLAUDE.md §6) — 한 사이클 질문 *최대 3회*.

질문 패턴:
> 어떤 화면을 만드세요? *왜 묻냐면, 만드는 도구가 달라져요.*
>
> - **웹 화면** (브라우저에서 보는 화면)
> - **앱 화면** (휴대폰에서 보는 화면)
> - **잘 모르겠어요** → 기본 추천: 웹 화면

### 3. 기본 추천 스택 적용

PRD §8 추천 기준. 사용자 선택과 무관하게 *추가 질문 없이* 기본값으로 셋업.

| 선택 | 스택 |
|---|---|
| 웹 | Tailwind CSS + shadcn/ui + Next.js (App Router) + TypeScript + lucide-react |
| 앱 | React Native (Expo) + NativeWind |
| 잘 모르겠어요 | 웹 기본값 |

세부 옵션(라우터·번들러·테스트 도구 등)은 *묻지 않는다*. 기본 추천이 디폴트.

### 4. 프로젝트 초기화 (정형 명령)

#### 4.1 패키지 매니저 결정
빈 디렉토리라 lockfile 없음 → **기본 `npm`** (가장 보편). 사용자 환경에 다른 매니저 흔적 없으면 npm 고정.

#### 4.2 초기화 명령

웹 (Next.js):
```
npx create-next-app@latest . \
  --ts --tailwind --eslint --app \
  --src-dir=false --import-alias "@/*" \
  --use-npm --no-turbopack
```
주의: 빈 디렉토리(또는 `.git`만 있는 경우)에서 `.`을 타깃. 비어있지 않으면 §1에서 이미 중단됐어야 함.

shadcn/ui 초기화 (웹만):
```
npx shadcn@latest init -d
npx shadcn@latest add button card input
```
기본 컴포넌트 3개를 박아둬야 디자이너가 곧장 변형해서 첫 화면 만들 수 있음.

앱 (Expo + NativeWind):
```
npx create-expo-app@latest . --template blank-typescript
npm install nativewind
npm install --save-dev tailwindcss@latest
npx tailwindcss init
```
NativeWind 설정(`babel.config.js`, `tailwind.config.js` content 경로)은 공식 docs 그대로.

명령 실패 시 → `error-translator`로 위임 (네트워크·권한·이미 존재 등).

### 5. 디자이너 폴더 규약 생성

PRD §8 디자이너 프로젝트 폴더 규약. 빈 디렉토리에 생성:

```
asset/    .gitkeep    # 이미지·아이콘·폰트
mock/     .gitkeep    # 가짜 데이터
components/           # 재사용 컴포넌트 (Next.js create 시 이미 생기면 스킵)
```

`.gitkeep` 빈 파일로 폴더 자체 추적. 디자이너가 "이미지 추가해줘" 했을 때 자동으로 `asset/`에 들어갈 단일 위치 보장.

### 6. `package.json` scripts 보장 (auto-validate 표준 키)

`auto-validate` Skill은 `package.json` scripts를 *우선* 호출함(CLAUDE.md §9). 새로 만든 프로젝트에 표준 키가 박혀 있어야 fallback에 빠지지 않음.

`Read` `package.json` → `Edit`로 보장:

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "typecheck": "tsc --noEmit"
  }
}
```

이미 있는 키는 건드리지 않고, **누락된 표준 키만 추가**:
- `lint` — 없으면 `next lint` (Next) 또는 `eslint .` (그 외)
- `typecheck` — 없으면 `tsc --noEmit`
- `check` — 박지 않음 (선택 키, 사용자가 후에 박을 수 있음)

`tsconfig.json`이 없으면 `tsc --noEmit`이 깨지므로 typecheck 박기 전 `tsconfig.json` 존재 확인 필수. 없으면 `npx tsc --init`을 먼저.

### 7. `CLAUDE.project.md` 생성 (placeholder 채워넣기)

`plugin/templates/CLAUDE.project.md` 템플릿을 기반으로 프로젝트 루트에 생성. 묻지 말고 기본 placeholder로 채운다 — 결정 피로 최소화.

기본 채워넣기:

| 필드 | 기본값 | 사용자 사후 변경 가능 |
|---|---|---|
| `{{서비스명}}` | 폴더 이름 (`basename "$PWD"`) | ✓ |
| `{{서비스 목적}}` | "(아직 정해지지 않음 — 화면 만들면서 자연스럽게 채워질 거예요)" | ✓ |
| `{{사용자층}}` | "(아직 정해지지 않음)" | ✓ |
| `{{스택}}` | 선택한 스택 (Next.js + Tailwind + shadcn/ui 등) | — |
| `{{디자인 시스템 토큰}}` | shadcn 기본 토큰 (color·radius·spacing 기본값 그대로) | ✓ |
| `## 사용 가능한 컴포넌트` | shadcn으로 박은 `Button`·`Card`·`Input` 한 줄씩 | 자동 갱신 |

placeholder가 비어 있는 채로 둬도 동작은 한다 — 디자이너가 화면 만들면서 자연스럽게 채울 수 있게 *질문하지 않고 일단 시작*.

### 7.1 `./CLAUDE.md` import 라인 보장 (방어적)

`CLAUDE.project.md`는 비표준 이름이라 새 대화 시작 시 자동 로드 X — 자동 로드되는 `./CLAUDE.md`에 `@CLAUDE.project.md` import 한 줄을 박아둬야 새 대화에서도 디자인 토큰·컴포넌트 인덱스·페르소나 요약이 이어진다. `/kd:디자인초기설정`이 정상 흐름에서 이미 박지만, 사용자가 슬래시 없이 자연어로 `new-service`를 바로 발동한 경우를 위한 *방어적 보장*.

처리 절차:

1. **`Read ./CLAUDE.md`** — 파일 존재·내용 확인.

2. **시작 마커(`<!-- kd:designer-mode:start -->`) 발견** → 스킵(`/kd:디자인초기설정`이 이미 박음).

3. **마커 부재** → `/kd:디자인초기설정` §2.2와 *동일한 분기*로 추가:
   - `./CLAUDE.md` 부재: `touch ./.kd-no-prior-claude-md` 후 `Write ./CLAUDE.md`로 마커 격리 + import 한 줄만 박기.
   - `./CLAUDE.md` 존재: `cp ./CLAUDE.md ./CLAUDE.md.kd-backup-<YYYYMMDD-HHmm>` 백업 후 끝에 마커 격리 import 라인 append.
   - 마커 블록은 항상:
     ```
     <!-- kd:designer-mode:start -->
     @CLAUDE.project.md
     <!-- kd:designer-mode:end -->
     ```

4. **검증** — 처리 후 마커 쌍이 정확히 1쌍인지 `Read`로 확인. 0·2쌍 이상이면 응답에 경고 1줄.

### 8. 셋업 직후 검증 + 첫 화면

마지막 단계로 두 가지 자동 호출:

1. **`auto-validate` 호출** (Task tool, Haiku)
   - lint + typecheck 통과 확인. 셋업 직후 깨진 상태 노출 방지.
   - fail 시 `error-translator`로 위임.
2. **`preview` 호출 권유** (자동 호출 X — 사용자 확인 후)
   - 응답 끝 다음 행동: "이제 첫 화면 한번 띄워볼까요?"
   - 사용자가 "응"이면 `preview` Skill로.
3. **사이클 시작 시점 기록** (`export-handoff`용 안전망)
   - `auto-validate` 통과 후 `git init && git add -A && git commit -m "초기 셋업"`까지 *자체적으로* 진행했다면(셋업 끝에 첫 commit이 있다면), `git rev-parse HEAD`를 `./.claude/.kd-session-base`에 박는다.
   - **이미 파일이 있으면 덮어쓰지 X** (`/kd:디자인초기설정`이 먼저 박았을 수 있음 — 처음 박는 1회만 책임).
   - 자체 first commit이 *없는* 흐름(이 Skill은 git init/first commit을 자동으로 만들지 않음)이면 스킵하고 `safe-save` 첫 호출의 §0 안전망에 의존.
   - `.gitignore` 처리는 `/kd:디자인초기설정` §4.1과 동일(`.claude/.kd-session-base` 한 줄 자동 추가, 기존 줄 보존).

### 9. 응답 가공 (호출 측 톤)

이 Skill은 Sonnet Subagent로 정형 셋업을 수행하지만, 사용자 노출 응답은 페르소나 톤.

응답 패턴 (성공):
> **새 프로젝트 셋업** 끝났어요 — `asset/`, `mock/`, `components/` 폴더와 기본 컴포넌트(`Button`·`Card`·`Input`) 박아뒀어요.
>
> 사용한 도구는 **Tailwind**(스타일), **shadcn/ui**(기본 컴포넌트), **Next.js**(웹 프레임), **TypeScript**(타입 검사)예요. 이름이 어색해도 신경 안 쓰셔도 돼요 — 디자인하면서 자연스럽게 익숙해질 거예요.
>
> 이제 첫 화면 한번 띄워볼까요?

## Subagent 위임
- **이 Skill 자체가 Sonnet Subagent로 동작** (`model: sonnet`) — 결정 흐름 + 셋업, 중간 난이도 (PRD §12)
- 내부 위임:
  - `auto-validate` (Task tool, Haiku) — 셋업 후 검증
  - `error-translator` (메인 가로채기) — 초기화 명령 실패 시
  - `preview` (사용자 동의 후) — 첫 화면 띄우기

## 응답 톤
- 한국어, 비유 + 용어 한글 병기 (`designer-persona` 글로벌 원칙)
- 셋업 단계 풀어 설명 X — "셋업 끝났어요" 한 줄로 충분
- 응답 끝 다음 행동 1개 제안 — 거의 항상 "첫 화면 띄워볼까요?"
- 결정 피로 최소화: 질문 1개(웹/앱)만, 나머지는 기본값

## 의존
- 다른 Skill: `auto-validate` (셋업 후 검증), `preview` (첫 화면), `error-translator` (실패 시), `designer-persona` (톤), `design-system-guard` (이후 컴포넌트 인덱스 갱신 위임)
- 외부 도구: `Bash` (`npx create-next-app`/`shadcn init`/`expo`/`npm`), `Read`/`Edit` (`package.json`), `Write` (`.gitkeep`, `CLAUDE.project.md`), `AskUserQuestion` (웹/앱)
- 템플릿: `plugin/templates/CLAUDE.project.md`
- 셋업 책임: `package.json` scripts에 `lint`/`typecheck` 박기 (CLAUDE.md §9, `auto-validate`가 호출하는 표준 키)
- 참조: PRD §5 new-service, §8 기본 추천 스택·폴더 규약, §12 라우팅
