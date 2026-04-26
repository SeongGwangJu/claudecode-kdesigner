---
description: |
  저장 — 임시저장도 진짜저장도 모두 commit 기반(stash 안 씀). 호출 직전 `auto-validate` 트리거 → 자연 한국어 commit 메시지 자동 생성 → push 여부 분기. 비파괴적 git 보장(`reset --hard`/`push --force`/`stash drop` 절대 X).

  발동 예시 (사용자 자연어):
  - "저장해줘", "지금까지 한 거 저장"
  - "임시저장", "잠깐 저장만"
  - "올려줘", "원격에 올려줘"

  사용 시점: 디자이너가 작업 중간이나 마무리 시점에 저장 의도를 표현할 때. /임시저장도 /저장도 동일 모델, 차이는 메시지 정성·push 분기뿐.
model: haiku
---

## 목적
git 추상화된 저장. 디자이너 화면에 `commit`/`push` 단어가 단독으로 떠오르지 않게 하고, 비파괴 정책을 1순위로 둔다.

## 발동 조건

### 발동
- 저장·올림 의도의 자연어 (위 예시 + 동의어)
- 다른 Skill 흐름 마무리 단계에서 명시 호출

### 발동 X
- 검증만 원하는 경우 ("점검해줘"/"한번 돌려봐") → `auto-validate` 직접 또는 `quality-check`
- 사용자가 "되돌려"/"취소" 명시 → `/kd:되돌리기`

## 처리 흐름

### 1. 변경 규모 판정 (auto-validate 발동 여부)
저장 직전 검증을 *필요할 때만* 한다 (CLAUDE.md §9):

| 변경 성격 | 검증 |
|---|---|
| 컴포넌트 추가·구조 변경·로직 변경 | `auto-validate` 호출 |
| 텍스트 사소한 변경(레이블·문구만, 5줄 미만) | 스킵 |
| `mock/`·`asset/` 변경만 | 스킵 |

### 2. `auto-validate` 호출 → 결과 분기
`Task` tool로 `auto-validate` Subagent 호출. 정형 결과로 분기:

- `status: pass` → 다음 단계
- `status: skipped` → 다음 단계 (검증 환경 없음)
- `status: fail` → `error-translator`로 stderr 위임. 자동 회복 성공 시 재검증, 실패 시 두 블록 패턴 응답하고 commit 중단

### 3. 자연 한국어 commit 메시지 생성
`git diff --stat` + 변경 파일 경로·주요 변경 줄을 메인 모델이 1줄 요약 (Haiku Subagent 내부에서). "임시저장"/"저장" 톤 차이만 둔다.

| 발동 자연어 | 메시지 톤 |
|---|---|
| "저장해줘" / "올려줘" | "메인 화면 카드 색 부드럽게 다듬기" 식 *서술형* |
| "임시저장" / "잠깐 저장만" | "임시 저장 — 작업 중 (메인 화면)" 식 *작업 중* 표시 |

규칙:
- 영어 단독 토큰 X (변경 파일명은 백틱으로)
- 30자 내외 한국어 한 줄 (긴 본문은 두 번째 줄에 옵션)

### 4. commit (비파괴)
```
git add -A     # 디자이너는 staging 개념 모름 — 기본은 전부
git commit -m "<생성한 한국어 메시지>"
```

비파괴 정책 (CLAUDE.md §3):
- `git reset --hard`, `git push --force`, `git stash drop` 절대 X
- `--amend`도 X (이미 push된 경우 위험) — 새 commit으로
- stash 미사용 (저장 모델 통일)

### 5. push 여부 분기

| 조건 | 동작 |
|---|---|
| 발동 자연어가 "올려줘"/"원격에 올려줘" + 원격 있음 | push 자동 |
| 발동 자연어가 "저장해줘" + 원격 있음 | `AskUserQuestion`: "원격에도 올릴까요?" + "잘 모르겠어요" 옵션 (기본 X) |
| 발동 자연어가 "임시저장" | push X (로컬만) |
| 원격 없음 (`git remote -v` 비어있음) | commit만, push 안내 X |

push 시 `origin <current-branch>` 지정. force 류 X.

### 6. 응답 가공 (호출 측 톤)
이 Skill은 Haiku Subagent로 정형 결과를 반환하지만, 메인 호출 측에서 디자이너 톤으로 가공한다.

응답 패턴:
> **저장**(`commit`)했어요 — "메인 화면 카드 색 부드럽게 다듬기" 라는 메모로 한 시점 묶어뒀어요. 나중에 이 시점으로 다시 돌아올 수 있어요.

push 동반 시:
> **저장 + 원격 업로드**(`commit + push`)까지 끝났어요 — 다른 분도 이 작업을 받아볼 수 있어요.

## Subagent 위임
- **이 Skill 자체가 Haiku Subagent로 동작** (`model: haiku`) — git diff 분석 + 한국어 메시지 생성 + 정형 commit/push, 모두 정형 입출력
- 내부에서 `auto-validate` 추가 위임 (Task tool, Haiku) — 검증
- 검증 fail 시 `error-translator`로 위임 (메인 가로채기)
- PRD §12 라우팅 표 일치

## 응답 톤
- 한국어, 응답 끝 다음 행동 1개 제안 (`designer-persona` 글로벌 원칙)
- `commit`/`push` 단독 노출 X — 패턴: **저장** (`commit`), **원격 업로드** (`push`)
- 다음 행동 예: "이제 화면 한번 보여드릴까요?" / "이제 점검 한번 돌려볼까요?"

## 의존
- 다른 Skill: `auto-validate` (호출 직전 검증), `error-translator` (검증 실패 회복), `designer-persona` (톤)
- 외부 도구: `Bash` (`git status`/`add`/`commit`/`diff`/`remote -v`/`push` — 비파괴만), `Task` (auto-validate 위임), `AskUserQuestion` (push 분기)
- 참조: PRD §5 safe-save, CLAUDE.md §3 비파괴적 git, §9 lint/build 트리거 조건
