# 0→1 셋업 명령 + DESIGN.md 옵션 + import 라인

## §1.5 DESIGN.md 옵션 (질문 1/3)

`https://getdesign.md/` 표준의 `DESIGN.md`(디자인 시스템 명세 표준)를 *지금 가져올지* 묻는다. 1차 셋업에서 토큰을 명확히 박을지, 우리 기본 토큰으로 시작할지의 분기.

> 디자인 시스템 명세(`DESIGN.md`)를 *지금 가져오시겠어요?* 색·간격·둥글기 같은 토큰을 *한 파일에* 명시해둔 표준 형식이에요(`getdesign.md` 사이트에서 골라 복사하는 형태).
>
> - **지금은 우리 기본 토큰으로 시작** (권장 — `shadcn/ui` 기본값, 작업 중 필요하면 나중에 추가) — *결정 피로 최소화*
> - **`DESIGN.md`를 가지고 있어요** (프로젝트 루트에 두시고 ↵Enter — 자동 인식해서 1순위 토큰 소스)
> - **잘 모르겠어요** → 기본값: 우리 기본 토큰으로 시작

선택:
- *기본 토큰 시작* 또는 *잘 모르겠어요* → §2 진행
- *DESIGN.md 가지고 있어요* → `Glob ./DESIGN.md` 재확인. 발견되면 §2 진행하되 §7에서 `CLAUDE.project.md` §디자인 시스템 §철학 안내 인용구 끝에 `> DESIGN.md를 1순위 소스로 사용 중 — 토큰·컴포넌트 규약은 그 파일이 단일 진실.` 한 줄. 못 찾으면 *"DESIGN.md를 못 찾았어요 — 프로젝트 루트에 두신 뒤 다시 한번만 알려주시면 함께 진행해요"* 한 줄 후 *기본 토큰* fallback.

## §2 질문 (질문 2/3)

결정 피로 최소화 — 한 사이클 질문 *최대 3회* (§1.5 + §2 = 2회).

> 어떤 화면을 만드세요? *왜 묻냐면, 만드는 도구가 달라져요.*
>
> - **웹 화면** (브라우저에서 보는 화면)
> - **앱 화면** (휴대폰에서 보는 화면)
> - **잘 모르겠어요** → 기본 추천: 웹 화면

## §3 기본 추천 스택

사용자 선택과 무관하게 *추가 질문 없이*:

| 선택 | 스택 |
|---|---|
| 웹 | Tailwind CSS + shadcn/ui + Next.js (App Router) + TypeScript + lucide-react |
| 앱 | React Native (Expo) + NativeWind |
| 잘 모르겠어요 | 웹 기본값 |

세부 옵션(라우터·번들러·테스트) *묻지 않음*.

## §4 초기화 명령

### §4.1 패키지 매니저

빈 디렉토리 → **기본 `npm`** (가장 보편).

### §4.2 명령

**웹 (Next.js)**:

```
npx create-next-app@latest . \
  --ts --tailwind --eslint --app \
  --src-dir=false --import-alias "@/*" \
  --use-npm --no-turbopack
```

빈 디렉토리(또는 `.git`만)에서 `.` 타깃. 비어있지 않으면 §1에서 이미 중단.

**shadcn/ui 초기화 (웹만)**:

```
npx shadcn@latest init -d
npx shadcn@latest add button card input
```

기본 컴포넌트 3개 — 디자이너가 곧장 변형해서 첫 화면.

**앱 (Expo + NativeWind)**:

```
npx create-expo-app@latest . --template blank-typescript
npm install nativewind
npm install --save-dev tailwindcss@latest
npx tailwindcss init
```

NativeWind 설정(`babel.config.js`·`tailwind.config.js` content)은 공식 docs.

명령 실패 → `error-translator`로 위임.

## §5 디자이너 폴더 규약

```
asset/    .gitkeep    # 이미지·아이콘·폰트
mock/     .gitkeep    # 가짜 데이터
components/           # 재사용 컴포넌트 (Next.js create 시 이미 생기면 스킵)
```

## §7.1 글로벌 미학 학습 시드

`~/.claude/CLAUDE.md` §미학 학습의 자동 누적 슬롯(`avoidance`·`tone-extracted`)이 채워져 있으면 *프로젝트 미학 시작점*으로:

1. `Read ~/.claude/CLAUDE.md` → §미학 학습 슬롯 추출.
2. `avoidance` → `CLAUDE.project.md` §피하고 싶은 디자인 (이 프로젝트 한정).
3. `tone-extracted` "톤 단어" → §톤 한 단어.

전역이 비어 있거나 없으면 시드 X — `aesthetic-guard`가 첫 작업 시.

시드는 *시작점*일 뿐 — 이 프로젝트만의 다른 톤이면 사용자가 첫 작업 때 덮어쓸 수 있음.

## §7.2 `./CLAUDE.md` import 라인 (방어적)

`/kdesigner:프로젝트시작`이 정상 흐름에서 박지만, 자연어로 `new-service` 바로 발동한 경우 *방어적 보장*.

1. `Read ./CLAUDE.md`.
2. 시작 마커 발견 → 스킵.
3. 마커 부재 → `/kdesigner:프로젝트시작` §3.2와 *동일한 분기*:
   - 파일 부재: `touch ./.kd-no-prior-claude-md` 후 `Write`로 마커 + import.
   - 파일 존재: `cp ./CLAUDE.md ./CLAUDE.md.kd-backup-<YYYYMMDD-HHmm>` 후 끝에 마커 격리 append.
   - `./DESIGN.md` 있으면 `@DESIGN.md` 한 줄 추가:
     ```
     <!-- kd:designer-mode:start -->
     @DESIGN.md
     @CLAUDE.project.md
     <!-- kd:designer-mode:end -->
     ```
4. 검증 — 마커 쌍 정확히 1쌍. 0·2쌍 이상이면 경고 1줄.

## §8 셋업 직후 검증 + 첫 화면

1. **`auto-validate` 호출** (Task, Haiku) — lint + typecheck. fail 시 `error-translator`.
2. **`preview` 호출 권유** (자동 호출 X — 사용자 확인 후). 응답 끝 "이제 첫 화면 한번 띄워볼까요?".
3. **사이클 시작 시점 기록** — `auto-validate` 통과 후 `git init && git add -A && git commit -m "초기 셋업"`까지 *자체적으로* 진행했다면 `git rev-parse HEAD`를 `./.claude/.kd-session-base`에. **이미 파일 있으면 덮어쓰지 X** — 처음 박는 1회만. 자체 first commit이 *없는* 흐름이면 스킵하고 `safe-save` 첫 호출의 §0 안전망에 의존. `.gitignore` 처리는 `/kdesigner:프로젝트시작` §4와 동일.
