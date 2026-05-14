# §2~§5. sync 흐름 (remote·분석·cherry-pick·충돌 회복)

## §2. remote 등록 + fetch

```bash
git remote get-url kd-source 2>/dev/null || git remote add kd-source <URL>
git fetch kd-source <branch> --depth=200
```

- remote 이름 `kd-source` 고정 (다른 remote와 충돌 X)
- `<URL>`·`<branch>`는 §1에서 읽은 슬롯 값
- `--depth=200` — 운영 레포가 대용량일 때 부담 완화. 변경분이 더 오래된 경우 deepen 1회

fetch 실패(네트워크·인증) → `error-translator` 가로채기. SSH key 문제면 슬롯의 URL이 SSH 형식인지 점검, 디자이너 환경은 https 권장 안내 1줄.

## §3. 미반영 commit 분석

`source-repo` 슬롯의 `last_sync_sha`(없으면 `진단 시점 SHA`)를 기준으로:

```bash
BASE_SHA="$(<last_sync_sha 또는 진단 시점 SHA>)"
git log ${BASE_SHA}..kd-source/<branch> --no-merges --pretty=format:'%H%x09%s'
```

비어있으면 — "이미 최신이에요" 한 줄 + 종료 (slot의 `마지막 sync 시점`만 *지금*으로 갱신).

각 commit `$SHA`에 대해 *파일 분류*:

```bash
git show --name-only --pretty=format: $SHA | grep -v '^$'
```

`<!-- kd:slot:publishing-boundary -->` 허용/금지 패턴으로 *디자인/비디자인* 가른다(슬롯 부재 시 `publishing-guard` §4 기본값 — 단일 진실 공유). 결과:

| 분류 | 판정 | 처리 |
|---|---|---|
| **디자인-only** | 모든 파일이 *디자인 영역* | §4 cherry-pick 후보 |
| **혼합** | 디자인·비디자인 모두 | §4에서 AskUserQuestion 1회 |
| **비디자인-only** | 모든 파일이 *비디자인 영역* | *알림만*, cherry-pick X |

분류 결과를 *건수 요약*으로 사용자에 1회 노출(§5 동의 직전).

## §4. cherry-pick (디자인 영역만)

**디자인-only commit 일괄 cherry-pick**:

```bash
git cherry-pick -x --allow-empty $SHA_LIST   # commit별로 순차
```

`-x`로 commit 메시지에 *원본 SHA 흔적* — 디자이너가 나중에 추적 가능. `--allow-empty`는 *디자인 부분이 이미 적용된* 경우 안전 통과.

**혼합 commit** — `AskUserQuestion` 1회 (commit 단위가 아니라 *혼합 그룹 전체* 1회 — 결정 피로 최소화):

> 본 레포에 *디자인·비디자인 변경이 섞인* commit이 **N개** 있어요. 어떻게 할까요?
> - **디자인 영역만 부분 흡수** (`git apply` 패치, 권장)
> - **전체 commit cherry-pick** (비디자인 영역도 — 다음 인계 시 가드가 검토 항목으로 박아둠)
> - **건너뛰기** (이번 sync에선 제외, 다음에 재시도)
> - **잘 모르겠어요** → 권장(부분 흡수)

분기:
- **부분 흡수**: commit별로 `git show $SHA -- <디자인 파일 목록> | git apply --3way`. `--3way`는 충돌 정보 보존. 비디자인 파일 손대지 X.
- **전체 cherry-pick**: `git cherry-pick -x $SHA` 후 *각 비디자인 변경 한 건씩* `handoff_review_queue`에 push (publishing-guard와 같은 큐 공유 — `export-handoff`가 다음 회차 *§디자인 외 변경* 섹션에 자동 첨부).
- **건너뛰기**: skip.

**비디자인-only commit**: 흡수 X. *알림 목록*으로 §6 응답에 박는다 (파일·줄 없이 commit subject 1줄).

## §5. 충돌 안전 회복

cherry-pick·git apply가 충돌 반환:

1. **상태 진단** — `git status --porcelain | grep '^UU'` 또는 `git apply` stderr.
2. **즉시 안전 복귀**:
   - cherry-pick 진행 중이면 `git cherry-pick --abort`
   - apply만 시도한 거면 `git checkout -- <충돌 파일>` (apply는 워킹트리만)
   - 어떤 경우에도 `git reset --hard`·`git push --force` 금지 (비파괴 git)
3. **친화 안내**:
   > 일부 파일이 *디자이너 작업과 본 레포 변경이 같은 줄*에서 만나서 그대로 합치기 어려웠어요 — 안전하게 *그 변경만 빼고 복귀*했어요. 다른 변경은 정상 흡수돼있어요.
   >
   > 충돌난 자리:
   > - `components/Button.tsx`
   > - ...
4. `AskUserQuestion`:
   > 이 자리들 어떻게 정할까요?
   > - **디자이너 작업 유지** (본 레포 변경 무시)
   > - **본 레포 변경으로 덮기** (디자이너 작업 줄 X — 위 줄은 `git revert`로 되돌릴 수 있으니 안심)
   > - **같이 보면서 정하기** (파일 열어 한 줄씩)
   > - **잘 모르겠어요** → 권장(같이 보기)
5. 답:
   - *디자이너 우선* → 그 자리는 *건너뛰기* (다음 sync에서 재시도 가능)
   - *본 레포 우선* → `git checkout kd-source/<branch> -- <파일>` 후 `git add` + `git commit` (별도 commit, 메시지 "본 레포 변경 적용 — *디자이너 줄 위에 덮음*")
   - *같이 보기* → 파일별 메인 모델 가공 (충돌 마커 정리 + 디자이너 친화 안내 후 사용자 확인)

## §6. source-repo 슬롯 갱신

성공 commit 한 건이라도 들어왔으면(혹은 *이미 최신* 분기여도) §1에서 읽은 슬롯을:

```
- **마지막 sync 시점**: {{YYYY-MM-DD HH:mm KST}}, SHA `<새 kd-source/<branch> HEAD>`
```

`Edit`로 *그 한 줄만*. 다른 필드(`원본 URL`/`branch`/`진단 시점 SHA`)는 손대지 X — 진단 시점 SHA는 *최초 변환* 기록으로 보존.

## §7. 응답 패턴

**Case 1 — 이미 최신**:
> 본 레포에 *디자이너 작업 이후 새 변경이 없어요*. 이미 최신 상태예요. 슬롯의 *마지막 sync 시점*만 지금으로 갱신해뒀어요.

**Case 2 — 정상 흡수**:
> 본 레포 갱신분을 디자인 레포로 가져왔어요.
>
> - **디자인 영역 흡수**: N개 (별도 저장 표식으로 묶임, 나중에 그 시점으로 되돌릴 수 있어요)
> - **비디자인 영역**: M개 — 개발자 영역이라 *건드리지 않았어요*. 본 레포에서 그대로 확인 가능
> - **혼합 commit 부분 흡수**: K개 (디자인 부분만 받음)
>
> *마지막 sync 시점*은 지금으로 갱신해뒀어요.

비디자인-only commit 있으면 *알림 목록*을 응답 끝 접은글에 1줄 subject만.

**Case 3 — 충돌 복귀**: §5 친화 안내 결과 그대로.
