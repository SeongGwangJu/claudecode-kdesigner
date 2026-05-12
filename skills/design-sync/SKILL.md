---
description: |
  본 레포(원본 운영 코드) → 디자인 레포 *Pull 기반 sync*. `import-existing` A 분기로 디자인 모드 변환을 마친 뒤 *그 사이* 개발자가 본 레포에 추가한 변경을 디자인 영역만 골라 흡수한다. 비디자인 영역(prod 경계) 변경은 *알림만* — 디자인 레포는 prod 코드를 직접 받지 X. 충돌 시 `git cherry-pick --abort`로 안전 복귀 + 친화 안내 + AskUserQuestion 1회. 비파괴 git 엄수(force push·hard reset 절대 X). sync 후 `<!-- kd:slot:source-repo -->`의 `last_sync_sha` 갱신.

  발동 예시:
  - "본 레포에서 가져오기", "원본 변경분 가져와줘"
  - "최신화해줘", "갱신해줘"
  - "원본 새로 받아줘", "본 레포에 뭐 바뀐 거 가져와"

  사용 시점: `import-existing` A 분기 완료(`CLAUDE.project.md` §source-repo 슬롯 채워짐) 이후, 본 레포에 누적된 개발자 변경을 디자인 레포로 합칠 때.
model: inherit  # CLAUDE.md §11 — 충돌 안전 회복 결정·디자이너 친화 응답이 컨텍스트 의존
---

## 목적
*양방향 머지의 git 복잡도*를 디자이너에게 떠넘기지 않고, *디자인 영역만 흡수* + *비디자인 영역은 알림*으로 끊어 안전한 갱신을 1회성 명령으로 처리한다. 디자인 영역/비디자인 영역 *분류*는 `publishing-guard`와 같은 `<!-- kd:slot:publishing-boundary -->` 슬롯을 참조 — 단일 진실, 중복 정의 X.

## 발동 조건

### 발동
- "최신화"/"갱신"/"본 레포 가져오기"/"원본 변경분" 류 자연어
- `import-existing` A 분기 후 *시간 경과* 응답에 1회 권유 (`프로젝트시작` 재실행 시 §7에서)

### 발동 X
- `source-repo` 슬롯 비어있음 — A 분기 미수행. 응답에 "본 레포 정보가 없어요. 먼저 *기존 프로젝트 가져오기*부터" 1줄.
- 토큰·컴포넌트 *변경* 의도 ("색 바꿔줘") → `design-system-guard`
- *새로 시작* 의도 → `new-service`

## 처리 흐름

### §1. 사전 조건 확인

`Read ./CLAUDE.project.md`로 다음 슬롯 동시 확인:

| 슬롯 | 부재·빈값 시 |
|---|---|
| `<!-- kd:slot:source-repo -->` `원본 URL`/`branch` | "원본 정보가 없어요. *기존 프로젝트 가져오기*를 먼저 부르세요" 한 줄 + 중단 |
| `<!-- kd:slot:design-mode-config -->` 토글 변수 | (선택) — 비어있어도 진행은 가능. 다만 디자인 모드 변환 *없이* sync는 의미 적음 — 응답에 1줄 첨부 |
| `<!-- kd:slot:publishing-boundary -->` | 비어있으면 hook 기본값(Next.js 기준)으로 진행, 응답 본문에 *왜 그 가정*인지 1줄 |

미커밋 변경 가드 — `git status --porcelain` 결과 *비어있지 않으면* 중단:
> 지금 *저장 안 된 변경*이 있어요. 먼저 *'저장해줘'* 한 번 부르신 뒤 다시 *'최신화'* 해주세요.

이유: cherry-pick은 깨끗한 워킹트리에서만 안전. 디자이너가 작업 중인 변경을 sync에 휩쓸리지 않게.

### §2. remote 등록 + fetch

```bash
git remote get-url kd-source 2>/dev/null || git remote add kd-source <URL>
git fetch kd-source <branch> --depth=200
```

- remote 이름 `kd-source` 고정 (다른 remote와 충돌 X)
- `<URL>`·`<branch>`는 §1에서 읽은 슬롯 값
- `--depth=200` — 운영 레포가 대용량일 때 부담 완화. 변경분이 더 오래된 경우 deepen 1회

fetch 실패(네트워크·인증) → `error-translator` 가로채기. SSH key 문제면 슬롯의 URL이 SSH 형식인지 점검, 디자이너 환경은 https 권장 안내 1줄.

### §3. 미반영 commit 분석

`source-repo` 슬롯의 `last_sync_sha`(없으면 `진단 시점 SHA`)를 기준으로:

```bash
BASE_SHA="$(<last_sync_sha 또는 진단 시점 SHA>)"
git log ${BASE_SHA}..kd-source/<branch> --no-merges --pretty=format:'%H%x09%s'
```

결과 비어있으면 — "이미 최신이에요" 한 줄 + 종료 (slot의 `마지막 sync 시점`만 *지금*으로 갱신).

각 commit `$SHA`에 대해 *파일 분류*:

```bash
git show --name-only --pretty=format: $SHA | grep -v '^$'
```

`<!-- kd:slot:publishing-boundary -->` 허용/금지 패턴으로 매 파일을 *디자인/비디자인*으로 가른다(슬롯 부재 시 `publishing-guard` §4 기본값 사용 — 가드와 단일 진실 공유). 그 결과 commit을 3분류:

| 분류 | 판정 | 처리 |
|---|---|---|
| **디자인-only** | 모든 파일이 *디자인 영역* | §4 cherry-pick 후보 |
| **혼합** | 디자인·비디자인 파일 모두 포함 | §4에서 AskUserQuestion 1회 |
| **비디자인-only** | 모든 파일이 *비디자인 영역* | *알림만*, cherry-pick X |

분류 결과를 *건수 요약*으로 사용자에 1회 노출(§5 동의 직전).

### §4. cherry-pick (디자인 영역만)

**디자인-only commit 일괄 cherry-pick**:

```bash
git cherry-pick -x --allow-empty $SHA_LIST   # commit별로 순차
```

`-x` 옵션으로 commit 메시지에 *원본 SHA 흔적*을 남김 — 디자이너가 나중에 어디서 왔는지 추적 가능. `--allow-empty`는 *디자인 부분이 이미 적용된* 경우 안전 통과.

**혼합 commit**:

`AskUserQuestion` 1회 (commit 단위가 아니라 *혼합 commit 그룹 전체*에 1회 — CLAUDE.md §6 결정 피로 상한):

> 본 레포에 *디자인·비디자인 변경이 섞인* commit이 **N개** 있어요. 어떻게 할까요?
> - **디자인 영역만 부분 흡수** (`git apply` 패치, 권장)
> - **전체 commit cherry-pick** (비디자인 영역도 함께 — 다음 인계 시 가드가 검토 항목으로 박아둠)
> - **건너뛰기** (이번 sync에선 제외, 다음에 재시도)
> - **잘 모르겠어요** → 권장(부분 흡수)

각 분기:
- **부분 흡수**: commit별로 `git show $SHA -- <디자인 파일 목록> | git apply --3way` 시도. `--3way`는 충돌 정보 보존. 비디자인 파일은 손대지 X.
- **전체 cherry-pick**: `git cherry-pick -x $SHA` 후 *각 비디자인 변경 한 건씩* `handoff_review_queue`에 push (publishing-guard와 같은 큐 공유 — `export-handoff`가 다음 회차 *§디자인 외 변경* 섹션에 자동 첨부).
- **건너뛰기**: skip.

**비디자인-only commit**: 흡수 X. *알림 목록*으로 §6 응답에 박는다 (파일·줄 없이 commit subject 1줄).

### §5. 충돌 안전 회복

cherry-pick·git apply가 충돌 반환(`exit code != 0`):

1. **상태 진단** — `git status --porcelain | grep '^UU'` 또는 `git apply` stderr에서 충돌 파일 추출.
2. **즉시 안전 복귀**:
   - cherry-pick 진행 중이면 `git cherry-pick --abort`
   - apply만 시도한 거면 `git checkout -- <충돌 파일>` (apply가 워킹트리에만 영향)
   - 어떤 경우에도 `git reset --hard`·`git push --force` 금지 (CLAUDE.md §3)
3. **친화 안내**:
   > 일부 파일이 *디자이너 작업과 본 레포 변경이 같은 줄*에서 만나서 그대로 합치기 어려웠어요 — 안전하게 *그 변경만 빼고 복귀*했어요. 다른 변경은 정상 흡수돼있어요.
   >
   > 충돌난 자리:
   > - `components/Button.tsx`
   > - ...
4. `AskUserQuestion` 1회:
   > 이 자리들 어떻게 정할까요?
   > - **디자이너 작업 유지** (본 레포 변경 무시)
   > - **본 레포 변경으로 덮기** (디자이너 작업 줄 X — 위 줄은 `git revert`로 되돌릴 수 있으니 안심)
   > - **같이 보면서 정하기** (파일 열어 한 줄씩)
   > - **잘 모르겠어요** → 권장(같이 보기)
5. 답에 따라:
   - *디자이너 우선* → 그 자리는 *건너뛰기*로 마무리 (다음 sync에서 재시도 가능)
   - *본 레포 우선* → `git checkout kd-source/<branch> -- <파일>` 후 `git add` + `git commit` (별도 commit, 메시지 "본 레포 변경 적용 — *디자이너 줄 위에 덮음*")
   - *같이 보기* → 파일별 메인 모델 가공 (충돌 마커 정리 + 디자이너 친화 한 줄 안내 후 사용자 확인)

### §6. source-repo 슬롯 갱신

성공 commit 한 건이라도 들어왔으면(혹은 *이미 최신* 분기여도) §1에서 읽은 슬롯을:

```
- **마지막 sync 시점**: {{YYYY-MM-DD HH:mm KST}}, SHA `<새 kd-source/<branch> HEAD>`
```

`Edit`로 *그 한 줄만* 갱신. 다른 필드(`원본 URL`/`branch`/`진단 시점 SHA`)는 손대지 X — 진단 시점 SHA는 *최초 변환* 기록으로 보존.

### §7. 응답 가공

#### Case 1 — 이미 최신
> 본 레포에 *디자이너 작업 이후 새 변경이 없어요*. 이미 최신 상태예요. 슬롯의 *마지막 sync 시점*만 지금으로 갱신해뒀어요.

#### Case 2 — 정상 흡수
> 본 레포 갱신분을 디자인 레포로 가져왔어요.
>
> - **디자인 영역 흡수**: N개 (별도 저장 표식으로 묶임, 나중에 그 시점으로 되돌릴 수 있어요)
> - **비디자인 영역**: M개 — 개발자 영역이라 *건드리지 않았어요*. 본 레포에서 그대로 확인 가능
> - **혼합 commit 부분 흡수**: K개 (디자인 부분만 받음)
>
> *마지막 sync 시점*은 지금으로 갱신해뒀어요.

비디자인-only commit이 있으면 *알림 목록*을 응답 끝 접은글 형태로 1줄짜리 subject만 노출(`- <짧은 commit subject>`).

#### Case 3 — 충돌 복귀
§5 친화 안내 결과 그대로.

### §8. 자가 점검

응답 직전 체크:
- [ ] `git status --porcelain` 결과 깨끗한가 (cherry-pick·apply 잔재 X)
- [ ] *force push·hard reset·stash drop* 사용 X (§3 비파괴 git)
- [ ] 슬롯 `last_sync_sha`·`마지막 sync 시점` 둘 다 갱신
- [ ] 디자이너 영역/비디자인 영역 분류 — `publishing-boundary` 슬롯(또는 hook 기본값)만 참조했는가 (직접 패턴 정의 X — §12 범용성)
- [ ] 혼합 commit 처리에 사용자 1회 동의를 받았는가

## Subagent 위임
- 이 Skill 자체: `inherit` — 분류 자체는 정형(파일 경로 매칭)이지만 *충돌 안전 회복 결정·디자이너 친화 응답*에 디자인 컨텍스트 필요. CLAUDE.md §11 (a)·(b)·(c) 모두 부분만 충족 — 모델 다운그레이드 X. 11-G에서 일괄 재검토.
- 내부 위임:
  - `error-translator` (메인 가로채기) — fetch 실패·인증 실패·apply 충돌의 자동 회복 시도
  - 부분 흡수·전체 cherry-pick의 후속 *commit 메시지* 자연 한국어 가공은 메인 모델 직접 (safe-save §3 흐름 차용)

## 응답 톤
- 한국어, 비유 + 용어 한글 병기 (`designer-persona` 글로벌 §)
- *복귀 가능성* 강조 — "안전하게 빼고 복귀했어요"·"되돌릴 수 있어요"
- 비디자인 영역 노출 시 *판단 추가 X* — "개발자 영역이라 건드리지 않았어요" 사실만
- 응답 끝 다음 행동 1개 + 자연어 1개 (§7) — 정상 흡수 후엔 "이제 *'보여줘'* 한 마디면 새 변경이 어떻게 보이는지 띄워드릴게요"

## 의존
- 다른 Skill: `import-existing`(§3-D 변환 + §7 `source-repo` 슬롯 박기 — *선행*), `publishing-guard`(분류 슬롯·hook 기본값 공유 + 혼합 commit 전체 cherry-pick 분기에서 `handoff_review_queue` push 공유), `export-handoff`(§4.3에서 큐 pop), `safe-save`(미커밋 변경 가드 시 권유), `error-translator`(fetch·apply 실패)
- 외부 도구: `Read`/`Edit`/`AskUserQuestion`/`Bash`(`git remote`/`fetch`/`log`/`show`/`cherry-pick`/`apply`/`status`/`rev-parse`)
- 템플릿: `CLAUDE.project.md` 슬롯 — `source-repo`(R/W last_sync_sha만), `design-mode-config`(R), `publishing-boundary`(R)
- 세션 state: `${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugin-data/kd}/sessions/<id>.json` `handoff_review_queue: [...]` — 혼합 commit *전체 cherry-pick* 분기에서 push만, pop X (export-handoff 책임)
- 추적: IMPROVEMENTS §F2-#4, ROADMAP Phase 11-F, PRD §5 design-sync
