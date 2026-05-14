---
description: 기존 프로젝트에 디자이너가 안전하게 끼어들기 — 입력 4분류(전체 레포·디자인+페이지 추출분·디자인 시스템만·컴포넌트 일부)로 자동 분기, A 분기는 prod 경계 손대지 않고 인증·API stub 격리 + 에러 노출 차단 레이어. 빈 디렉토리가 아닌 기존 코드베이스에서 — "기존 프로젝트에서 가져오기"·"운영 중인 서비스 받았는데 디자인만 손볼게"·"이 프로젝트에 디자이너 모드 켜줘"·"있는 거 분석해서 셋업해줘" 같은 자연어에 발동.
model: inherit  # CLAUDE.md §11 — 입력 4분류·디자인 시스템 추출·격리 모듈 설계가 디자인 컨텍스트 의존
---

## 목적

기존 코드 훼손 위험을 최소화하며 디자이너가 끼어들 수 있는 *단일 참조점*(컴포넌트·페이지 인덱스 + 디자인 시스템 메모 + 변환 결과)을 만든다.

*읽기·문서화 중심*, 코드 수정은 폴더 추가(`mock/`·`asset/`)·문서 추가가 기본. 단 *전체 레포(A 분기)*에 한해 디자인 모드 격리 모듈을 *prod 경계 밖*에서 별도 commit 단위로 박는다(§3-D).

## 발동 / 발동 X

- ✅ "기존 프로젝트에서 가져오기"·"회사 레포 끼어들기"·"운영 레포 받았는데"
- ✅ `/kdesigner:프로젝트시작` 직후 비어있지 않은 디렉토리 → 자연 권유
- ✅ `new-service` 시작 시 §1 가드에서 기존 작업 흔적 발견 → 권유
- ❌ 완전히 빈 디렉토리 → `new-service`
- ❌ 디자인 토큰 *변경* 의도("색 좀 바꿔줘") → `design-system-guard`

## 처리 흐름

### §0. 입력 종류 분류

자동 판정 신호 + `AskUserQuestion` 1회 확인 → A/B/C/D 분기 라우팅. 자세한 표·라우팅은 [references/input-classification.md](./references/input-classification.md).

```
A 전체 레포     → §1 → §2 → §3-A/B/C → §3-D 운영 레포 변환 → §4 + §4.5 → §5/§6/§7
B 추출분        → §1 → §2 → §3-A/B/C → §4 + §4.5 → §5/§6/§7  (§3-D 스킵)
C 시스템만      → §1 → §2 → §3-A → §7 시드 → new-service 합류 권유
D 일부          → §1 → §4 (단편) → §7 부분 + 한계 1줄
```

### §1. 기존 상태 진단 (읽기만)

`Glob`/`Read`로 한 번에. **수정 X**. `hasDesignMd`·`framework`·`hasAuth`·`hasApiRoutes`·`routePaths`·`pwd`/`gitRoot` 등 산출 변수와 §1.3 라우트 패턴 휴리스틱(결정론 매트릭스 X — *프레임워크 신호 추론 → 패턴 휴리스틱*, 범용성 우선)·§1.4 실행 위치 분기는 [references/diagnostic.md](./references/diagnostic.md).

§1.4 *빈 디렉토리* — 사용자가 이 Skill에 *들어왔다는 사실 자체*가 기존 코드를 가져올 결이라는 신호. 빈 폴더라는 환경 조건으로 새 디자인 결로 우회 X. 어떤 종류 입력을 옮길 수 있는지 방향만 안내 후 종료.

### §2. 디자인 시스템 존재 여부

`hasDesignMd` → DESIGN.md 1순위 / shadcn 류 / 커스텀 / 부분만 / 없음 5분기. 자세한 표는 [references/diagnostic.md](./references/diagnostic.md) §2.

### §3-A. 있음 — 추출·요약

**DESIGN.md 우선** — `hasDesignMd` = true면 *그 파일이 1순위 토큰 소스*. 코드(`tailwind.config`/`globals.css`) 추출은 *보조*. 충돌 시 DESIGN.md가 단일 진실. `CLAUDE.project.md` §디자인 시스템 §철학 슬롯에 `> DESIGN.md를 1순위 소스로 사용 — 토큰·컴포넌트 규약은 그 파일이 단일 진실.` 한 줄.

토큰 추출(색·spacing·radius·typography) → `CLAUDE.project.md` §design-tokens *요약*. 추출은 *프로젝트 미학 슬롯에도 시드* — 추출한 폰트가 한글 친화(Pretendard/Spoqa/SUIT 등)면 §철학·§톤 후보, dominant 색·둥글기 결도. 비어있는 차원은 *여기서 묻지 X* — `aesthetic-guard`가 첫 작업 시 자연스레.

> ⚠️ 한계: `tailwind.config.*`이 동적 코드(함수 호출·외부 파일 합치기)면 토큰 추출이 부분만 될 수 있어요.

### §3-B. 없음 — 만들기 권유 (메시지만)

**1차에선 권유 메시지만**. 자동 생성 X.

> 이 프로젝트는 **공통 디자인 약속**(`design system`)이 아직 정해져 있지 않은 것 같아요. 색·간격·둥글기 같은 공통 기준이 없으면 화면마다 따로 놀게 돼요.
>
> 두 가지 길 — **개발자에게 요청**(가장 안전)·**지금 일단 만들어 보기**(나중에 충돌 가능, 다음 버전에서 추가 예정).
>
> 일단은 **있는 그대로 받아서 진행**할 수 있어요 — 컴포넌트만 정리해드릴게요.

미학 컨텍스트는 *빈 슬롯*으로 두고 `aesthetic-guard`가 첫 작업 시 자연스레 채움.

### §3-C. 부분만 있음 — 정리 권유

§3-A처럼 추출하되 응답에 "토큰화가 일부만 되어 있어서 새 화면 만들 때 일관성이 흔들릴 수 있어요" 한 줄.

### §3-D. 운영 레포 → 디자인 레포 변환 (A 분기 전용)

핵심 원칙: ***prod 경계 코드(`middleware*`·`app/api/**`·`lib/**`·`hooks/**`·`stores/**`)는 절대 분기를 박지 X***. 인증·API 우회는 *별도 모듈에 격리*해 컴포넌트 *import 경로 차원에서만* 분기. 변경은 *별도 commit 단위*.

9단계 처리 절차(인증 stub·API stub·디자인 모드 토글·환경변수 파일·scripts 추가·에러 노출 차단 레이어·컴포넌트 import 분기 변환·별도 commit·결과 기록)는 [references/design-mode-conversion.md](./references/design-mode-conversion.md).

§publishing-boundary 슬롯은 *템플릿 기본값 그대로* 두기(빈 골격) — 사용자/개발자가 본 레포 구조 보고 수정 가능. 기본값은 hook이 직접 적용하므로 비어있어도 가드 동작.

### §4 / §4.5. 컴포넌트·페이지 인덱스 (핵심 산출물)

`CLAUDE.project.md` §components·§pages 슬롯 일괄 생성. 50개 상한, 외부 데이터 의존 컴포넌트는 ⚠️ + mock 안내. 상세 절차·라인 형식은 [references/index-pages-components.md](./references/index-pages-components.md).

후속 갱신·회전은 `design-system-guard`로 위임 (정본: `plugin/SCHEMA.md` §2.3). 이 Skill은 *초기 일괄 생성*까지만.

### §5 / §6 / §7. 폴더·scripts·`CLAUDE.project.md`

- §5 디자이너 폴더 규약(`asset/`·`mock/`·`components/`)
- §6 `package.json` scripts(`lint`·`typecheck`·`dev:kd-design`)
- §7 `CLAUDE.project.md` 정보 종합 + §7.1 import 라인 *방어적 보장* + §7.2 사이클 base SHA 기록

상세는 [references/project-md-write.md](./references/project-md-write.md). 이미 `CLAUDE.project.md` 있으면 **덮어쓰지 X** — `.new`로 + 머지 권유.

### §8. 응답 가공 (분기별)

**A 분기 성공**:
> **운영 레포 변환** 끝났어요 — **Next.js + Tailwind + shadcn/ui** 조합, 인증·API는 *별도 모듈로 격리*했어요(`mock/auth-stub.ts`·`mock/api-stubs/`·`lib/design-mode/`). 운영 코드는 *손대지 않았어요*.
>
> 발견한 컴포넌트 **N개** + 페이지 **M개**를 `CLAUDE.project.md`에 정리했고, 그중 **K개** 컴포넌트는 외부 데이터에 의존해서 미리보기 시 mock이 필요.
>
> 첫 화면 한번 띄워볼까요? "**보여줘**" 한 마디면 돼요. 새 화면을 만드시려면 "**여기에 새 화면 하나 추가하자**" 한 마디로 바로 시작할 수 있어요.

**B/C/D 성공**은 §3 결과 본문 + 다음 행동 1개. 트리거 자연어는 *맥락에 가까운 1개* — 변환 직후엔 "**보여줘**"(확인), 인덱스만 정리된 분기엔 "**여기에 새 화면 하나 추가하자**"(시작). **§3-B 없음** 분기는 그 메시지를 응답 본문에 그대로.

## Subagent 위임

이 Skill 자체는 *메인 모델 컨텍스트* (`model: inherit`). 입력 4분류·디자인 시스템 추출·격리 모듈 설계·컴포넌트 우선순위는 *디자인 퀄리티 영향*이라 다운그레이드 위험. (a)/(b)/(c) 사유 명확 충족 X면 inherit.

내부 위임: `error-translator` (메인 가로채기) — 파일 읽기·인코딩 실패 시.

*수정* 책임 분리 — 인덱스 갱신은 `design-system-guard`, prod 경계 가드는 `publishing-guard`.

## 응답 톤

- 한국어, 비유 + 용어 한글 병기 (`designer-persona`)
- 기존 코드 훼손 *명시적 안심* — "기존 파일은 손대지 않았어요" (A 분기는 *prod 경계 코드*에 한정)
- 디자인 시스템 *없음* 분기에서 부담 안 주기 — "일단 받아서 진행" 길 열어둠
- A 분기 응답에 *별도 commit 단위* 언급 — 디자이너가 본 레포 반영 시 안전
- 응답 끝 다음 행동 1개 + 자연어 1개 — "첫 화면 한번 띄워볼까요? '**보여줘**' 한 마디면 돼요" 류

## 자가 점검

- [ ] §0 입력 4분류 확정 후 분기 진행 (확인 1회 한도)
- [ ] §1 진단은 *읽기만*, 수정 0
- [ ] A 분기에서 prod 경계 코드(`middleware*`·`app/api/**`·`lib/**`·`hooks/**`·`stores/**`)에 분기 박지 X
- [ ] `CLAUDE.project.md` 이미 있으면 덮어쓰지 X (`.new`로)
- [ ] `./CLAUDE.md` import 라인은 백업 후 마커 격리 블록으로
- [ ] 응답 끝 다음 행동 1개 + 트리거 자연어 1개

## 의존

- **다른 Skill**: `design-system-guard`(인덱스 갱신 위임)·`auto-validate`·`preview`·`error-translator`·`designer-persona`·`publishing-guard`(A 분기 후 prod 경계 가드)·`design-sync`
- **외부 도구**: `Glob`/`Grep`/`Read`/`Write`/`Edit`/`Bash`(`git`·`pwd`·`cp`·`mkdir`·`touch`·`echo`)/`AskUserQuestion`
- **템플릿**: `plugin/templates/CLAUDE.project.md` (새 슬롯 `source-repo`·`pages`·`design-mode-config` 포함)
