---
description: 개발자에게 디자이너 작업물을 회차별로 인계 정리. 디자이너가 화면 작업을 마치고 넘기기 직전 — "개발자한테 넘기기"·"인계 정리해줘"·"넘길 거 정리해줘"·"이거 마무리하고 넘기자" 같은 자연어에 발동, 작업 진행 중 단순 저장은 `safe-save`로 분기.
model: inherit  # CLAUDE.md §11 — 변경 분류·SCHEMA 추론·TOPIC 산출·영역 분리가 컨텍스트 의존
---

## 목적
디자이너 작업물을 *그대로 받아 실서비스에 통합 가능한 상태*로. 합격선 = 개발자가 1분 안에 "어디를 실제 데이터에 연결해야 하는지" 파악.

## 발동 / 발동 X

- ✅ "개발자한테 넘기기"·"인계 정리"·"넘길 거 정리"·"마무리 + 인계 의도"
- ❌ 작업 중 단순 저장 → `safe-save`
- ❌ 점검만 → `quality-check`

## 처리 흐름

### 1. 인계 직전 점검 (자동)

`quality-check` 호출 (Task tool) — 반응형·색 대비·alt·토큰 어긋남.

| 결과 | 동작 |
|---|---|
| 빨강 1+ | **중단** + "이거 먼저 같이 고치고 넘길까요?" |
| 노랑만 | 진행 + 회차 파일 *알려진 이슈* 섹션 |
| 모두 초록 | 진행 |

이어 `auto-validate`(Task, Haiku) — lint·typecheck. fail이면 `error-translator` 거쳐 재검증.

### 2. 영역 분리 — 디자이너 vs 개발자

기존 프로젝트 시나리오에선 *이번 사이클에 디자이너가 추가/변경한 부분만* — 그러지 않으면 옛 mock·옛 import까지 끌어와 잘못된 인계.

이번 사이클 변경분(`CHANGED_FILES`) 산출 절차는 [references/cycle-diff-scan.md](./references/cycle-diff-scan.md). BASE_SHA 정상 = `git diff` 기반 / 부재·무효 = 전체 grep + 응답에 한계 1줄.

분류 (CHANGED_FILES 안에서):

| 분류 | 위치·기준 | 회차 파일 표시 |
|---|---|---|
| **디자이너 영역** | `components/`·`app/**/page.tsx`·`styles/`·`tailwind.config.*`·`asset/` | "그대로 가져가셔도 돼요" |
| **가짜 데이터** | `mock/**/*` | "여기 데이터를 실제 API/DB에 연결해주세요" |
| **연결 지점** | 이번 사이클 추가된 `mock/` import 줄 | "이 import를 실제 데이터 소스로 교체" |

### 3. 외부 데이터 의존 컴포넌트

회차 파일에선 *기존 참조*와 *이번 추가*를 분리(성격·갱신 시점이 달라 섞이면 시선 흐림).

- **기존 참조**: `CLAUDE.project.md` § 외부 데이터 의존 컴포넌트 *섹션 참조 1줄*만. 비어있거나 부재면(new-service 흐름) 이 하위 섹션 자체 스킵.
- **이번 추가**: §2 CHANGED_FILES 안 *새로 도입한 hook*(`useAuth`/`useSession`/`useQuery`/`useSWR`/`useMutation`/`fetch`/`axios`). 매치 0건이면 "이번 사이클에는 새로 도입한 데이터 hook이 없어요" 한 줄.

스캔 절차는 [references/cycle-diff-scan.md](./references/cycle-diff-scan.md) §데이터 hook.

#### 3.1 공유 이력 참조 (external-share 연동)

`CLAUDE.project.md`의 `<!-- kd:slot:share-history -->` 슬롯 — 비어있거나 슬롯 부재면 생략. 비어있지 않으면 INDEX.md *부재 분기 신규 생성 시*에만 *§외부 데이터 의존 컴포넌트 / 공유 이력* 옆에 행 개수 + 가장 최근 항목 1줄(자세한 표는 `CLAUDE.project.md` 참조). 회차 파일에선 재나열 X — 시점은 commit·파일명에 이미 있고, 공유 이력은 INDEX 한 곳 단일 진실.

목적: 개발자가 *이 디자인이 누구에게 언제 노출됐는지* 인계 시 INDEX 한눈에 파악.

### 4. 회차 파일 + INDEX.md

매 인계 = `handoff/{YYMMDD-HHmm}-{TOPIC}.md` 별도 파일 1개. `handoff/INDEX.md`가 회차 목록·미적용 카운트 자동 갱신.

TOPIC 산출·파일명·본문 템플릿·INDEX 부재·존재 분기·publishing-guard 큐 pop·mock SCHEMA 주석은 [references/round-file-template.md](./references/round-file-template.md).

핵심 원칙:
- TOPIC은 `safe-save` 위임 메시지와 *같은 1줄* — 파일명·회차 본문·commit 메시지 일관.
- 회차 파일 본문은 개발자 대상이라 영어 용어 OK. 0건 섹션 생략, `## 검증 결과`는 항상.
- 미적용 카운트·회차 수는 *grep 재계산* — 개발자가 `- [ ]`을 `- [x]`로 체크한 변화도 자연 반영, 별도 메커니즘 X.
- 기존 단일 `HANDOFF.md`가 있으면 *읽기 전용 archive*로 두고 새 회차부터 `handoff/` 폴더.
- 큐 비움은 *회차 파일 작성 성공 후*에만 — 실패 시 다음 회차 흡수, 멱등.

### 5. 인계 시점 commit (`safe-save` 위임)

인계는 *되돌릴 수 있어야 함*. `safe-save`로 회차 시점 명시 기록.

위임 메시지(자연어 인자 — §4 TOPIC 그대로):
> 인계 정리 — {TOPIC} (handoff/{YYMMDD-HHmm}-{TOPIC-slug}.md 생성, mock 데이터에 SCHEMA 주석 추가)

`safe-save`가 commit. push는 사용자에게 묻는다(safe-save 기본). 회차 파일의 `commit:` 줄은 commit 완료 후 `git rev-parse --short HEAD`로 `Edit`.

### 6. 응답 가공 (호출 측 톤)

응답 패턴(첫 회차·누적 회차·§디자인 외 변경 동반·`fresh-session-guide` 자동 트리거)은 [references/response-tone.md](./references/response-tone.md).

인계는 *큰 사이클의 마무리* — 성공 시 `fresh-session-guide` 자동 트리거(그 Skill의 §발동 X 조건 걸리면 침묵).

## Subagent 위임

이 Skill 자체는 *메인 모델 컨텍스트* (`model: inherit`). 변경 분류·SCHEMA 추론·TOPIC 산출·영역 분리는 디자인 컨텍스트 의존이라 다운그레이드 위험.

격리·정형 도구 사유 충족분만 위임:
- `quality-check` (Task) — 인계 전 점검. `quality-check`도 inherit이라 메인 컨텍스트 흐름 유지.
- `auto-validate` (Task, Haiku) — lint/typecheck. §11 (b)(c)
- `safe-save` (Task, Haiku) — 회차 시점 commit. §11 (b)(c)
- `error-translator` (메인 가로채기) — 검증·commit 실패 시

이 Skill은 *문서화·정리*만 담당. 코드 수정·개발자 측 통합은 안 함.

## 자가 점검

- [ ] CHANGED_FILES 안에서만 §2~§3 스캔 (BASE_SHA 부재 시 한계 1줄 노출)
- [ ] *기존 참조*와 *이번 추가*가 회차 파일에서 분리되어 있나
- [ ] TOPIC이 파일명·회차 본문·commit 메시지에 *같은 1줄*로 일관
- [ ] 0건 섹션 생략, `## 검증 결과`만 항상
- [ ] `publishing-guard` 큐 비움은 회차 파일 작성 성공 후
- [ ] 응답 끝 다음 행동 1개 + 트리거 자연어 1개 (designer-persona §7)

## 의존

- **다른 Skill**: `quality-check`·`auto-validate`·`safe-save`(§5 TOPIC 전달)·`import-existing`(§3 외부 데이터 의존 섹션)·`external-share`(§3.1 슬롯)·`publishing-guard`(§4 `handoff_review_queue` pop — 직접 호출 X, 큐 공유)·`error-translator`·`designer-persona`(톤)·`fresh-session-guide`(§6 성공 시 자동)
- **외부 도구**: `Read`/`Glob`/`Grep`·`Write`(회차 파일·INDEX 신규)·`Edit`(INDEX 갱신·commit sha 채움·mock SCHEMA)·`Bash`(`mkdir -p handoff/`·`TZ='Asia/Seoul' date`·`git rev-parse --short HEAD`·`grep`/`ls`/`awk`·`jq` 큐 pop)
- **세션 state**: `${CLAUDE_PLUGIN_DATA:-$HOME/.claude/plugin-data/kd}/sessions/<session_id>.json` — R(`handoff_review_queue` pop)·W(소비 후 빈 배열). 같은 파일을 `publishing-guard`가 push, `designer-persona`가 `commit_meaning_shown` 사용 — 키 단위 비간섭.
- **산출물**: `./handoff/{YYMMDD-HHmm}-{TOPIC-slug}.md`·`./handoff/INDEX.md`. 기존 `./HANDOFF.md`는 *읽기 전용 archive*로 보존.
- **참조 파일**: `CLAUDE.project.md` (외부 데이터 의존 컴포넌트·공유 이력 슬롯)
