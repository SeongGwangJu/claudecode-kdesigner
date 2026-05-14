---
description: 새 서비스 0→1 셋업 — 추천 스택(웹: Tailwind+shadcn/ui+Next.js+TypeScript / 앱: Expo+NativeWind)으로 폴더 구조·`CLAUDE.project.md`·`package.json` scripts까지 박아 디자이너가 첫 화면을 만질 수 있는 상태로. 사용자가 새로 만들겠다는 결을 표현한 직후 — "새 디자인 시작할게"·"새로 만들고 싶어"·"처음부터 만들어줘"·"빈 곳에서 시작"·"프로젝트 새로 셋업해줘" 같은 자연어. 빈 디렉토리라는 환경 조건만으로는 발동 X (의도 확인 우선, [[/kdesigner:프로젝트시작]] §5.1).
model: inherit  # CLAUDE.md §11 — 0→1 미학 결정·DESIGN.md 분기·placeholder 시드가 디자인 컨텍스트 의존
---

## 목적

30분 안에 새 서비스 0→1 셋업을 끝내고, 디자이너가 *첫 화면을 만들 수 있는 상태*까지. 결정 피로 최소화(기본 추천 우선), `auto-validate`가 호출할 표준 scripts 박기까지 이 Skill 책임.

## 발동 / 발동 X

- ✅ 사용자가 새로 시작하겠다는 결을 표현한 자연어
- ✅ `/kdesigner:프로젝트시작` §5.1 의도 확인 결과 새 디자인 결
- ❌ 기존 코드(`package.json`·`components/`) → `import-existing` 우선
- ❌ 슬래시 `/kdesigner:맨처음설정`·`프로젝트시작`은 *컨텍스트 켜기*만 — 실제 스택 셋업은 이 Skill

발동이 망설여지는 결:
- 디렉토리가 비어있다는 환경 조건 자체만으로 발동하면 *기존 코드를 풀어놓을 예정*이던 사용자의 결을 가로채게 된다. 환경 조건은 신호일 뿐 트리거가 아니다 — 의도 표현이 앞선다.

## 처리 흐름

### 1. 빈 디렉토리 확인

위험 회피 — 기존 작업 덮어쓰기 방지.

| 상태 | 동작 |
|---|---|
| 완전히 빈 | 진행 |
| `.git`만 | 진행 |
| `package.json` 또는 `components/` 존재 | **중단** + `import-existing` 권유 |
| `CLAUDE.project.md` 이미 존재 | **중단** + "이미 셋업되어 있어요" |

중단 응답:
> 이 폴더에 이미 작업한 흔적이 있어 보여요(`package.json` 발견). 새로 시작하면 기존 작업이 덮일 수 있어서, **기존 프로젝트 가져오기** 흐름이 더 안전해요. 그쪽으로 진행할까요?

### 1.5 ~ §5. 질문·스택·초기화·폴더

§1.5 DESIGN.md 옵션 (질문 1/3) · §2 웹/앱 (질문 2/3) · §3 기본 추천 스택 · §4 초기화 명령(웹·shadcn·앱) · §5 디자이너 폴더 규약(`asset/`·`mock/`·`components/`).

상세 질문 문구·명령·표는 [references/setup-commands.md](./references/setup-commands.md).

핵심 원칙:
- 한 사이클 질문 *최대 3회* (§1.5 + §2 = 2회, 세부 옵션 묻지 X).
- 패키지 매니저 = **기본 `npm`** (빈 디렉토리, lockfile 없음).
- 빈 디렉토리에서 `.` 타깃 — 비어있지 않으면 §1에서 중단.

### 6. `package.json` scripts 보장

`auto-validate`가 *우선* 호출할 표준 키. 새 프로젝트에 박혀 있어야 fallback에 빠지지 않음.

표준 키 정의·fallback·적용 절차는 `${CLAUDE_SKILL_DIR}/references/init-scripts-schema.md`. 단일 진실: `plugin/SCHEMA.md` §3.

핵심:
- `Read` `package.json` → 누락된 표준 키만 `Edit`로 추가 (이미 있는 키 건드리지 X).
- `tsconfig.json` 부재 시 → `npx tsc --init` 선행 필수 (`typecheck` 깨짐 방지).

### 7. `CLAUDE.project.md` 생성 (placeholder)

`plugin/templates/CLAUDE.project.md` 템플릿 기반 + 묻지 말고 기본 placeholder. 결정 피로 최소화.

핵심:
- `{{서비스명}}` ← `basename "$PWD"`
- 그 외 placeholder ← `${CLAUDE_SKILL_DIR}/references/placeholder-defaults.md` 기본값 (사용자가 미리 답한 값 있으면 우선)
- 자동 관리 슬롯(`components`·`last-work` 등)은 *해당 책임 Skill*이 갱신

placeholder 비어 있어도 동작 — *질문하지 않고 일단 시작*, 디자이너가 화면 만들면서 자연스레.

§7.1 글로벌 미학 학습 시드(`avoidance`·`tone-extracted` 자동 누적 슬롯이 채워져 있으면 프로젝트 시드로) + §7.2 `./CLAUDE.md` import 라인 *방어적 보장*은 [references/setup-commands.md](./references/setup-commands.md) §7.1·§7.2.

### 8. 셋업 직후 검증 + 첫 화면

1. **`auto-validate`** (Task, Haiku) — lint + typecheck.
2. **`preview` 호출 권유** (자동 X — 사용자 확인 후): "이제 첫 화면 한번 띄워볼까요?"
3. **사이클 시작 시점 기록** — 자체 first commit 있을 때만 `./.claude/.kd-session-base` (이미 있으면 덮지 X).

상세는 [references/setup-commands.md](./references/setup-commands.md) §8.

### 9. 응답 (호출 측 톤)

> **새 프로젝트 셋업** 끝났어요 — `asset/`·`mock/`·`components/` 폴더와 기본 컴포넌트(`Button`·`Card`·`Input`) 박아뒀어요.
>
> 사용한 도구는 **Tailwind**(스타일)·**shadcn/ui**(기본 컴포넌트)·**Next.js**(웹 프레임)·**TypeScript**(타입 검사)예요. 이름이 어색해도 신경 안 쓰셔도 돼요 — 디자인하면서 자연스럽게 익숙해질 거예요.
>
> 이제 첫 화면 한번 띄워볼까요?

## Subagent 위임

이 Skill 자체는 *메인 모델 컨텍스트* (`model: inherit`). 0→1 미학 결정·DESIGN.md 분기·기본 추천 스택 톤·placeholder 시드는 디자인 컨텍스트 의존이라 다운그레이드 위험.

내부 위임 (격리·정형):
- `auto-validate` (Task, Haiku) — 셋업 후 검증. §11 (b)(c)
- `error-translator` (메인 가로채기) — 초기화 명령 실패
- `preview` (사용자 동의 후) — 첫 화면. §11 (b)(c)

## 응답 톤

- 한국어, 비유 + 용어 한글 병기 (`designer-persona`)
- 셋업 단계 풀어 설명 X — "셋업 끝났어요" 한 줄로 충분
- 응답 끝 다음 행동 1개 — 거의 항상 "첫 화면 띄워볼까요?"
- 결정 피로 최소화: 질문 *최대 2회*, 나머지 기본값

## 자가 점검

- [ ] §1 빈 디렉토리 가드 — `package.json`·`components/`·`CLAUDE.project.md` 있으면 중단
- [ ] 질문 *최대 2회* (DESIGN.md + 웹/앱)
- [ ] 패키지 매니저 = npm 고정
- [ ] `package.json` scripts 표준 키 박힘 (`SCHEMA.md` §3)
- [ ] `CLAUDE.project.md` placeholder는 *질문 없이* 기본값
- [ ] 응답 끝 "첫 화면 띄워볼까요?" + 트리거 자연어

## 의존

- **다른 Skill**: `auto-validate`(셋업 후 검증)·`preview`(첫 화면)·`error-translator`(실패)·`designer-persona`(톤)·`design-system-guard`(이후 인덱스 갱신)
- **외부 도구**: `Bash`(`npx create-next-app`·`shadcn init`·`expo`·`npm`)·`Read`/`Edit`(`package.json`)·`Write`(`.gitkeep`·`CLAUDE.project.md`)·`AskUserQuestion`
- **템플릿**: `plugin/templates/CLAUDE.project.md`
- **셋업 책임**: `package.json` scripts에 `lint`/`typecheck` 박기 (`auto-validate` 표준 키)
