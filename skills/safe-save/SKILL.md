---
description: |
  저장(commit) — 임시저장도 진짜저장도 모두 commit 기반 (stash 안 씀). 호출 직전 auto-validate 트리거 → 자연 한국어 commit 메시지 자동 생성 → push 여부 분기. 비파괴적 git 보장.

  발동 예시 (사용자 자연어):
  - "저장해줘"
  - "임시저장"
  - "올려줘"
  - "지금까지 한 거 저장"

  사용 시점: 디자이너가 작업 중간/마지막 저장 의도. /임시저장도 /저장도 동일 모델, 차이는 메시지 정성뿐.
model: haiku
---

## 목적
git 추상화된 저장. 디자이너 화면에 `commit`/`push` 단어 노출 X.

## 발동 조건
- 발동: 저장·임시저장·올려줘 자연어
- 발동 X: 검증만 원할 때 (그땐 `auto-validate` 직접)

## 처리 흐름
> ⚠️ Phase 4 placeholder. 본 로직은 Phase 4에서 작성.
> 핵심:
> 1. `auto-validate` 트리거 (저장 직전 검증)
> 2. git diff → 자연 한국어 commit 메시지 자동 생성
> 3. commit (stash 안 씀)
> 4. push 여부 분기 (원격 있으면 묻고, 없으면 commit만)
> 5. **비파괴 보장**: `reset --hard`, `push --force`, `stash drop` 절대 X

## Subagent 위임
- 본 Skill 자체가 Haiku Subagent (git diff → 한국어 메시지, 정형 입출력)

## 응답 톤
- 한국어, "저장했어요" 비유, 다음 행동 1개 제안 (글로벌 원칙)
- "commit", "push" 단독 노출 X. 패턴: **저장** (`commit`)

## 의존
- 다른 Skill: `auto-validate` (호출 직전), `error-translator` (실패 회복)
- 외부 도구: Bash (`git` 명령 — 비파괴만)
