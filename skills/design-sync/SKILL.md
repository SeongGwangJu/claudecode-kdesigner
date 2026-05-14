---
description: 본 레포(원본 운영 코드) → 디자인 레포 *Pull 기반 sync* — `import-existing` A 분기 변환 후 본 레포에 누적된 개발자 변경을 디자인 영역만 골라 흡수, 비디자인 영역은 알림만. 충돌 시 `git cherry-pick --abort`로 안전 복귀 + AskUserQuestion 1회. 비파괴 git 엄수. "최신화해줘"·"갱신해줘"·"원본 변경분 가져와줘"·"본 레포에서 가져오기"·"본 레포에 뭐 바뀐 거 가져와" 같은 자연어에 발동.
model: inherit  # CLAUDE.md §11 — 충돌 안전 회복 결정·디자이너 친화 응답이 컨텍스트 의존
---

## 목적

*양방향 머지의 git 복잡도*를 디자이너에게 떠넘기지 않고, *디자인 영역만 흡수* + *비디자인 영역은 알림*으로 끊어 안전한 갱신을 1회성 명령으로. 디자인/비디자인 *분류*는 `publishing-guard`와 같은 `<!-- kd:slot:publishing-boundary -->` 슬롯 참조 — 단일 진실, 중복 정의 X.

## 발동 / 발동 X

- ✅ "최신화"·"갱신"·"본 레포 가져오기"·"원본 변경분"
- ✅ `import-existing` A 분기 후 *시간 경과* 응답에 1회 권유 (`프로젝트시작` 재실행 §7)
- ❌ `source-repo` 슬롯 비어있음 — A 분기 미수행. "본 레포 정보가 없어요. 먼저 *기존 프로젝트 가져오기*부터" 1줄.
- ❌ 토큰·컴포넌트 *변경* 의도 → `design-system-guard`
- ❌ *새로 시작* → `new-service`

## 처리 흐름

### §1. 사전 조건 확인

`Read ./CLAUDE.project.md`로 슬롯 동시 확인:

| 슬롯 | 부재·빈값 시 |
|---|---|
| `<!-- kd:slot:source-repo -->` `원본 URL`/`branch` | "원본 정보가 없어요. *기존 프로젝트 가져오기*를 먼저" + 중단 |
| `<!-- kd:slot:design-mode-config -->` 토글 변수 | (선택) — 비어있어도 진행, 다만 디자인 모드 변환 *없이* sync는 의미 적음 — 응답 1줄 |
| `<!-- kd:slot:publishing-boundary -->` | 비어있으면 hook 기본값(Next.js 기준), 응답 본문에 *왜 그 가정*인지 1줄 |

미커밋 변경 가드 — `git status --porcelain` 결과 *비어있지 않으면* 중단:
> 지금 *저장 안 된 변경*이 있어요. 먼저 *'저장해줘'* 한 번 부르신 뒤 다시 *'최신화'* 해주세요.

이유: cherry-pick은 깨끗한 워킹트리에서만 안전.

### §2~§5. remote·분석·cherry-pick·충돌 회복

`git remote add kd-source` → `git fetch` → `git log ${BASE_SHA}..` → 파일 분류(디자인-only/혼합/비디자인-only) → cherry-pick(`-x --allow-empty`) / 부분 흡수(`git apply --3way`) / 알림만 → 충돌 시 `git cherry-pick --abort` + 친화 안내 + AskUserQuestion 1회.

상세 명령·분류 표·혼합 commit 분기·충돌 안전 회복 5단계·응답 패턴 3종은 [references/sync-flow.md](./references/sync-flow.md).

### §6. source-repo 슬롯 갱신

성공 commit 한 건 이상(또는 *이미 최신*) → 슬롯의 `마지막 sync 시점`을 `Edit`로 *그 한 줄만*. 다른 필드(`원본 URL`·`branch`·`진단 시점 SHA`)는 *최초 변환* 기록으로 보존.

### §7. 응답 가공

Case 1 이미 최신 / Case 2 정상 흡수 / Case 3 충돌 복귀 — 패턴은 [references/sync-flow.md](./references/sync-flow.md) §7.

비디자인-only commit 있으면 *알림 목록*을 응답 끝 접은글 1줄 subject.

## 자가 점검

응답 직전 체크:
- [ ] `git status --porcelain` 결과 깨끗한가 (cherry-pick·apply 잔재 X)
- [ ] *force push·hard reset·stash drop* 사용 X (§3 비파괴 git)
- [ ] 슬롯 `last_sync_sha`·`마지막 sync 시점` 둘 다 갱신
- [ ] 디자이너/비디자인 분류 — `publishing-boundary` 슬롯(또는 hook 기본값)만 참조 (직접 패턴 정의 X — 범용 표현만)
- [ ] 혼합 commit 처리에 사용자 1회 동의

## Subagent 위임

이 Skill 자체: `inherit` — 분류 자체는 정형(파일 경로 매칭)이지만 *충돌 안전 회복 결정·디자이너 친화 응답*에 디자인 컨텍스트 필요. (a)·(b)·(c) 모두 부분만 충족 — 모델 다운그레이드 X.

내부 위임:
- `error-translator` (메인 가로채기) — fetch 실패·인증 실패·apply 충돌의 자동 회복
- 부분 흡수·전체 cherry-pick 후속 *commit 메시지* 자연 한국어 가공은 메인 모델 직접 (`safe-save` §3 흐름 차용)

## 응답 톤

- 한국어, 비유 + 용어 한글 병기 (`designer-persona`)
- *복귀 가능성* 강조 — "안전하게 빼고 복귀했어요"·"되돌릴 수 있어요"
- 비디자인 영역 노출 시 *판단 추가 X* — "개발자 영역이라 건드리지 않았어요" 사실만
- 응답 끝 다음 행동 1개 + 자연어 1개 — 정상 흡수 후 "이제 *'보여줘'* 한 마디면 새 변경이 어떻게 보이는지 띄워드릴게요"

## 의존

- **다른 Skill**: `import-existing`(§3-D 변환 + §7 `source-repo` 박기 — *선행*)·`publishing-guard`(분류 슬롯·hook 기본값 공유 + 혼합 commit 전체 cherry-pick 분기에서 `handoff_review_queue` push 공유)·`export-handoff`(§4.3에서 큐 pop)·`safe-save`(미커밋 변경 가드 권유)·`error-translator`
- **외부 도구**: `Read`/`Edit`/`AskUserQuestion`/`Bash`(`git remote`·`fetch`·`log`·`show`·`cherry-pick`·`apply`·`status`·`rev-parse`)
- **템플릿**: `CLAUDE.project.md` 슬롯 — `source-repo`(R/W last_sync_sha만), `design-mode-config`(R), `publishing-boundary`(R)
- **세션 state**: `${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugin-data/kd}/sessions/<id>.json` `handoff_review_queue` — 혼합 commit *전체 cherry-pick* 분기에서 push만, pop X (export-handoff 책임)
