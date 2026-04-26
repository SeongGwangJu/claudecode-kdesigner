---
name: fresh-session-guide
description: |
  세션이 충분히 무거워졌고 큰 흐름의 휴지점일 때, 디자이너에게 새 대화창으로 옮기길 *잔소리 없이 한 번* 권유. CLAUDE.project.md 자동 로드(import 라인) 덕분에 새 대화에서도 컨텍스트는 그대로 이어진다는 안심 메시지가 핵심. 같은 세션에서 권유는 1회만.

  주력 트리거는 *시스템 자가 점검* (designer-persona §6) — 사용자가 직접 부르는 일은 드물다.

  발동 예시 (사용자 자연어 — 보조, 드물게):
  - "대화 길어졌나?", "이거 무거워"
  - "새 대화 열까?", "새 창에서 시작해도 돼?"
  - "토큰 너무 쓰는 거 아냐?"

  사용 시점: (a) `export-handoff` 인계 사이클 마무리 직후, (b) 양적·질적 게이트 둘 다 yes일 때 designer-persona 자가 점검에서 자동 트리거, (c) 위 보조 자연어 발화 시. 같은 세션에서 1회만.
model: inherit
---

# fresh-session-guide

## 목적
세션이 길어진 시점에 디자이너에게 *새 대화창*으로 옮기길 권유. 핵심은 두 가지 — (1) 새 대화에서도 디자인 약속(컴포넌트 인덱스·토큰·페르소나)이 *그대로 이어진다*는 안심, (2) 같은 세션에서 *1회만*이라 잔소리가 되지 않게 하는 정밀 통제.

## 발동 조건

### 발동 (AND 게이트 — 양적 AND 질적 둘 다 yes)

**양적 게이트** (둘 중 하나 이상):
- hook이 박은 state 파일(`${CLAUDE_PLUGIN_DATA}/sessions/<session_id>.json`)의 `save_count >= 5`
- 또는 같은 state 파일의 `now - started_at >= 1h`
- **hook 미배포 환경 fallback**: 메인 모델 자가 카운트 — 현재 대화에서 *분명히 3회 이상 commit*이 있었다고 판단되는 경우 (느슨하게 잡되, 의심스러우면 발동 X)

**질적 게이트** (모델 자가 판단, 하나 이상 yes):
- 큰 흐름 마무리 직후 (`export-handoff` 완료, 인계 commit 직후)
- 한 결정/사이클 닫힘 (사용자 명시 발화 또는 흐름상 자명)
- 새 결정 영역으로 *전환 직전* (다음 작업이 이전 작업과 독립적)

### 발동 X (둘 다 yes여도 침묵)
- 사용자가 *방금* 새 발화를 시작 — 흐름 한가운데 끊지 않음
- 디버깅 진행 중 — 에러 회복 사이클 중간
- 같은 세션에서 이미 1회 권유함 — state `suggested: true`
- 사용자가 명시적으로 끄는 발화 ("계속 여기서 해" / "새 대화 안 열어")

## 처리 흐름

### 1. state 확인 (재권유 차단)

`${CLAUDE_PLUGIN_DATA}/sessions/<session_id>.json` 파일을 `Read`로 시도:
- 파일 부재 또는 hook 미배포 → 자가 카운트 fallback으로 진행
- `suggested: true` → 즉시 침묵, 처리 중단

### 2. 권유 메시지 노출 (응답 끝에 박기)

다음 톤 그대로 또는 톤만 다듬고 *내용은 보존*:

> 잠깐 제안 한 마디 — 지금까지 대화가 꽤 길어졌어요. **새 대화창**으로 옮기시는 게 가벼워요.
>
> *왜요?* 대화가 길수록 (1) 이전 대화 내용이 새 작업에 헷갈리게 끼어들고, (2) 매번 이전 대화를 다시 읽어오면서 비용도 쌓여요(한 번에 큰돈은 아니지만 길어질수록 누적돼요).
>
> **새 대화 여는 법**:
> - 터미널에서: `/clear`
> - 데스크톱/웹에서: `⌘ + N` (Mac) / `Ctrl + N` (Windows)
>
> *이 프로젝트의 모든 정보는 새 대화에서도 그대로 이어져요* — `./CLAUDE.md`가 디자인 약속(`@CLAUDE.project.md`)을 자동으로 불러와줘서, 새 창에서 "이어서 작업하자"라고 시작하면 바로 같은 자리예요.

규칙:
- 강제·재촉 X — "원하시면" 톤 유지
- 영어 단독 노출 X (`/clear`·`@CLAUDE.project.md`는 코드로 백틱 감싸 OK)
- 페르소나 톤 일관 (`designer-persona` §)

### 3. `CLAUDE.project.md`에 마지막 작업 한 줄 갱신 (다음 대화 부드럽게 잇기)

처리 절차:
1. `Read ./CLAUDE.project.md`
2. `## 마지막 작업` 섹션 검색:
   - **있으면**: 섹션 *끝*에 한 줄 추가 (이전 줄 보존, 누적 로그)
   - **없으면**: 파일 끝에 섹션 추가
3. 새 줄 형식: `- **<YYYY-MM-DD HH:MM>** — <이번 사이클 한 줄 요약>`
   - 시간: `date "+%Y-%m-%d %H:%M"` (Bash)
   - 한 줄 요약: `export-handoff` 완료 시점이면 그 commit 메시지에서, 그 외엔 메인 모델이 사용자 발화·작업 흐름에서 한 줄 추출
4. `Edit`으로 정확히 그 위치만 갱신 — 이전 줄·다른 섹션 절대 손대지 X

### 4. state 파일 갱신 (재권유 차단)

hook 배포 환경에서만:
- `${CLAUDE_PLUGIN_DATA}/sessions/<session_id>.json`의 `suggested`를 `true`로 갱신
- `jq` 또는 직접 JSON 재작성으로 `Bash`에서 처리:
  ```bash
  STATE_FILE="${CLAUDE_PLUGIN_DATA}/sessions/${CLAUDE_SESSION_ID}.json"
  if [ -f "$STATE_FILE" ]; then
    jq '.suggested = true' "$STATE_FILE" > "${STATE_FILE}.tmp" && mv "${STATE_FILE}.tmp" "$STATE_FILE"
  fi
  ```
- hook 미배포 환경에선 메인 모델이 *대화 메모리* 안에서 "이 세션에서 권유 완료" 표시 — 다시 점검 시 발동 X

## Subagent 위임
없음 — 메인 모델이 권유 톤 직접 가공. 잔소리 위험 정밀 통제가 핵심이라 위임 시 톤 일관성 깨질 수 있음. PRD §12 명시 X(자가 점검 보조 Skill로 메인 컨텍스트 비용 미미).

## 응답 톤
- 한국어, 페르소나 일관 (`designer-persona` §)
- 권유 끝에 다음 행동 1개 — 예: "이어서 다음 작업이 있으시면 새 대화창에서 *이어서 작업하자*로 시작해보세요"
- 강제·재촉 X — 디자이너가 무시해도 흐름 그대로

## 의존
- 다른 Skill: `designer-persona` (§6 자가 점검에서 트리거), `export-handoff` (가장 자연스러운 자동 트리거 시점), `safe-save` (양적 카운터의 hook 트리거 시점)
- 외부 도구: `Read`/`Edit` (`CLAUDE.project.md` 갱신), `Bash` (`date`, `jq` — state 갱신)
- 외부 자산: `${CLAUDE_PLUGIN_DATA}/sessions/<session_id>.json` (hook이 박는 state 파일), `./CLAUDE.project.md` `## 마지막 작업` 섹션
- 참조: PRD §6 의사결정 원칙(다음 행동 1개·결정 피로), CLAUDE.md §7 다음 행동 1개
