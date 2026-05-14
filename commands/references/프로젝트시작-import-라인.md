# §3.2 `./CLAUDE.md` import 라인 처리

`CLAUDE.project.md`(있다면 `DESIGN.md`)는 *비표준 이름*이라 새 대화 시작 시 자동 로드 X. 자동 로드되는 파일: `./CLAUDE.md`·`./.claude/CLAUDE.md`·`./CLAUDE.local.md`·`~/.claude/CLAUDE.md`.

자동 로드되는 `./CLAUDE.md`에 공식 `@<path>` import로 박아 *새 대화에서도 디자인 약속이 이어지게*.

## 마커 블록 내용 (§2 DESIGN.md 분기 반영)

| DESIGN.md 존재? | 마커 블록 |
|---|---|
| 있음 | `@DESIGN.md\n@CLAUDE.project.md` (2줄) |
| 없음 | `@CLAUDE.project.md` (1줄) |

## 처리 절차

1. **`./CLAUDE.md` 존재 여부** — `Read` 또는 `test -f ./CLAUDE.md`.

2-a. **없으면** (새로 생성):
   - `touch ./.kd-no-prior-claude-md` — 빈 마커 파일. `/kdesigner:디자인끄기`가 *우리가 만든 파일인지* 판단해서 통째 제거할 수 있게.
   - `Write ./CLAUDE.md`:
     ```
     <!-- kd:designer-mode:start -->
     @DESIGN.md
     @CLAUDE.project.md
     <!-- kd:designer-mode:end -->
     ```
     (DESIGN.md 없으면 `@DESIGN.md` 줄 제외)

2-b. **있으면** (기존 파일에 마커 격리해 추가):
   - **백업** — `cp ./CLAUDE.md ./CLAUDE.md.kd-backup-<YYYYMMDD-HHmm>` (`date +%Y%m%d-%H%M`). `/kdesigner:디자인끄기`에서 *원본 그대로* 복원할 수 있게.
   - **append** — 기존 파일 끝에 빈 줄 + 마커 격리 블록.

3. **마커 검증** — append/생성 후 `Read ./CLAUDE.md`로 다시 읽어 시작·끝 마커가 *정확히 1쌍*. 0쌍·2쌍 이상이면 응답 끝에 경고 1줄("`./CLAUDE.md`에 디자이너 마커가 정상이 아닌 상태예요 — 한 번 확인해주세요").

마커 사이는 *오직 `@DESIGN.md`(있을 때)와 `@CLAUDE.project.md` 줄만*. 디자인 시스템·페르소나 본문은 박지 않는다 — 본문은 그 파일들에 있고 `@import`이 자동 로드.

## §3.3 `CLAUDE.project.md` 생성

§3.1에서 *이어서 쓰기*로 복원했으면 스킵.

`plugin/templates/CLAUDE.project.md` 템플릿을 현재 디렉토리 루트에 `CLAUDE.project.md`로 생성:

- `Read` 템플릿 → `Write` 프로젝트 루트
- `{{서비스명}}`은 폴더 이름(`basename "$PWD"`)으로
- 나머지 `{{...}}`는 *그대로* — `new-service`/`import-existing`이 이후 채울 영역
- §2 DESIGN.md 존재 분기였다면 §철학 슬롯 안내 인용구 끝에 `> DESIGN.md를 1순위 소스로 사용 중 — 토큰·컴포넌트 규약은 그 파일이 단일 진실.` 추가 (placeholder 본문은 손대지 않음)

## §3.1 archived 발견 시 복원 분기

`./CLAUDE.project.md`은 *없는데* `./CLAUDE.project.md.kd-archived-*`가 하나 이상 있으면 — `/kdesigner:디자인끄기`로 끄고 다시 켜는 흐름.

`AskUserQuestion`:
> 이 폴더에 *이전에 디자이너 모드로 작업한 흔적*이 있어요(`CLAUDE.project.md.kd-archived-...`). 그때 정리해뒀던 디자인 약속·컴포넌트 정리를 *이어서* 쓸 수 있어요.
> - **이어서 쓰기** (이전 작업 그대로, 다시 분석 X)
> - **새로 시작** (이전 흔적 보관, 비어있는 상태로)
> - **잘 모르겠어요** → 기본값: 이어서 쓰기

선택:
- **이어서 쓰기**: `ls -t ./CLAUDE.project.md.kd-archived-* | head -1` → `mv`로 `./CLAUDE.project.md` 복원 (cp 아님 — 한 archive를 두 자리에 두지 않음). §3.2 import 라인은 복원된 파일 기준 진행. §3.3 스킵.
- **새로 시작**: archive 파일 *손대지 X*. §3.3부터 그대로.

복원 시 응답 1줄:
> 이전 작업 그대로 이어서 시작해요 — `CLAUDE.project.md.kd-archived-YYYYMMDD-HHmm`을 다시 살렸어요.

## §4. 사이클 시작 시점 기록 (export-handoff용)

`export-handoff`가 *이번 사이클 추가/변경 파일만* 인계 README에 정리할 기준점 SHA.

1. git 저장소 아니면 스킵 (`git rev-parse --git-dir 2>/dev/null` 실패).
2. commit 0개면 스킵 (`git rev-parse HEAD` 실패).
3. 그 외:
   - `mkdir -p ./.claude`
   - **이미 `.claude/.kd-session-base` 존재 시 덮어쓰지 X** — 처음 박는 1회만.
   - 부재 시: `echo "$(git rev-parse HEAD)" > ./.claude/.kd-session-base`
4. `.gitignore` 처리:
   - `.claude/.kd-session-base` 한 줄 없으면 *append* (기존 줄 보존).
   - `.gitignore` 자체 부재면 새로 만들어 그 줄만.
   - `.claude/` 디렉토리 자체는 gitignore X.

## §5.1 빈 디렉토리 — 의도 확인

빈 폴더에 가능한 결 두 가지 — *처음부터 새로* / *이미 있던 코드를 옮겨와 정리*. 가는 방향이 완전히 달라 어느 한쪽으로 미리 흘려보내지 않는다.

`AskUserQuestion` 1회. 옵션 문구·라벨은 현재 상황(전역 켜짐·DESIGN.md·직전 발화)에 맞춰 자연 생성. 두 결 + "잘 모르겠어요" 옵션.

- **새로 만드는 결** → `new-service` 흐름
- **기존 코드 가져오는 결** → 이 폴더에 분석할 코드가 없다는 사실 자체가 출발점. 사용자가 코드 옮길 수 있게 *방향* 안내(전체 레포/추출분/시스템 단독/일부), 옮긴 뒤 자연어로 `import-existing` 진입. 이 시점에 즉시 발동 X (대상이 아직 없음)

추가 분기 — `CLAUDE.project.md` §source-repo가 *채워져 있고* `마지막 sync 시점`이 *수일 이상 지났거나 비어있음*이면(`import-existing` A 분기 후 본 레포에 변경 누적 가능성) 권유 응답에 1줄:

> 원본 레포 갱신분 가져오려면 "**최신화해줘**" 한 마디면 돼요(`design-sync`).

슬래시로 직접 호출하지 않음 — *자연어 우선* 원칙대로 자연어 발화로 Skill 자동 발동.
