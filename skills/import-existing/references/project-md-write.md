# §7. `CLAUDE.project.md` 생성 + import 라인 + 세션 base

## §7. 정보 종합 → `CLAUDE.project.md`

`plugin/templates/CLAUDE.project.md` 템플릿 기반 + §3 추출 + §4 컴포넌트 + §4.5 페이지 + §3-D 결과:

- **서비스명**: 폴더 이름 또는 `package.json` `name`
- **사용된 스택**: `package.json` `dependencies` 핵심만
- **디자인 시스템 토큰**: §3 추출 요약 또는 "없음 + 권유 메시지"
- **§components 슬롯**: §4 인덱스
- **§pages 슬롯**: §4.5 인덱스
- **§source-repo 슬롯**: A 분기일 때 `git remote -v`로 원본 URL + 현재 branch + 진단 시점 SHA(`git rev-parse HEAD`). `design-sync` 후속에서 사용. 비 git 저장소면 *비워둠*.
- **§design-mode-config 슬롯**: A 분기 §3-D 결과 — 토글 변수명, mock 격리 경로, `dev:kd-design` 한 줄씩.
- **인계 주의사항**: "외부 데이터 의존 컴포넌트는 `mock/`로 가짜 데이터 박아 미리보기"

**글로벌 미학 학습 시드** — `~/.claude/CLAUDE.md` §미학 학습 자동 누적 슬롯이 채워져 있으면, 코드에서 *추출 불가능한 차원*만 시드: §피하고 싶은 디자인 ← 글로벌 §avoidance / §톤 ← 글로벌 §tone-extracted 후보, *코드 추출 톤과 충돌하면 코드 추출 우선*. 전역 비어 있으면 시드 X — `aesthetic-guard`가 첫 작업 시 자연스레.

이미 `CLAUDE.project.md`가 있으면 **덮어쓰지 X** — `CLAUDE.project.md.new`로 생성 + 머지 권유.

## §7.1 `./CLAUDE.md` import 라인 보장 (방어적)

`CLAUDE.project.md`는 비표준 이름이라 새 대화 시작 시 자동 로드 X — 자동 로드되는 `./CLAUDE.md`에 `@CLAUDE.project.md` import 한 줄. `/kdesigner:프로젝트시작`이 정상 흐름에서 박지만, 사용자가 슬래시 없이 자연어로 바로 발동한 경우 *방어적 보장*. `hasDesignMd`면 `@DESIGN.md`도 같은 마커 블록.

*백업 정책*:

1. `Read ./CLAUDE.md` — 존재·내용 확인.
2. 시작 마커(`<!-- kd:designer-mode:start -->`) 발견 → 스킵.
3. 마커 부재 + 파일 존재:
   - `cp ./CLAUDE.md ./CLAUDE.md.kd-backup-<YYYYMMDD-HHmm>` *반드시 백업 먼저*.
   - 빈 줄 + 마커 격리 블록 append. `hasDesignMd`면 `@DESIGN.md`도:
     ```
     <!-- kd:designer-mode:start -->
     @DESIGN.md
     @CLAUDE.project.md
     <!-- kd:designer-mode:end -->
     ```
   - 응답에 백업 경로 1줄.
4. 파일 부재: `touch ./.kd-no-prior-claude-md` 후 `Write ./CLAUDE.md`로 마커 격리 + import 라인.
5. 검증: 마커 쌍 정확히 1쌍. 0·2쌍 이상이면 경고 1줄.

## §7.2 사이클 시작 시점 기록 (export-handoff용)

`export-handoff`가 *이번 사이클 추가/변경 파일만* 인계 README에 정리할 기준점 SHA.

1. `test -f ./.claude/.kd-session-base` — 있으면 **덮어쓰지 X** (`/kdesigner:프로젝트시작`이 박았으면 그대로).
2. 부재 시: `mkdir -p ./.claude && echo "$(git rev-parse HEAD)" > ./.claude/.kd-session-base` (저장소 아니면 스킵)
3. `.gitignore` — `/kdesigner:프로젝트시작` §4와 동일 처리.

## §5. 디자이너 폴더 규약 추가

기존 폴더 *건드리지 않고* 누락만:

| 폴더 | 동작 |
|---|---|
| `asset/` | 없으면 `.gitkeep`. `public/`·`assets/` 있으면 그쪽으로 통일 안내 |
| `mock/` | 없으면 `.gitkeep`. A 분기면 §3-D에서 이미 채워짐. `__mocks__/`·`fixtures/` 있으면 통일 안내 |
| `components/` | 이미 있음 가정 (없으면 *프로젝트 자체 의심* — 중단) |

## §6. `package.json` scripts 보장

`auto-validate` 표준 키 점검:

| 키 | 부재 시 동작 |
|---|---|
| `lint` | 사용자에게 묻고 추가 |
| `typecheck` | 없으면 `tsc --noEmit` 추가 (단, `tsconfig.json` 있을 때만) |
| `dev:kd-design` | A 분기 §3-D에서 추가됨 (B/C/D 분기엔 추가 X) |

기존 scripts와 충돌하면 **묻지 말고 건드리지 X** — 위험 회피. 응답에 "lint/typecheck 명령이 표준이 아니어서 자동 검증이 일부 제한될 수 있어요" 한 줄.
