---
description: 외부 공유 (시안·배포) — 디자이너가 작업물을 *외부에 보여주려* 할 때 4단계 의도(잠깐/단기/지속/공개)와 trade-off, 사전 게이트 3중(빌드·민감정보·더미), 회사 프로젝트 가드. "이거 잠깐 보여줘"·"팀에 시안 돌리고 싶어"·"링크 만들어줘"·"올려줘"·"배포해줘" 같은 외부 공유 의도에 발동, 단순 저장(`safe-save`)·본인 미리보기(`preview`)·개발자 인계(`export-handoff`)와 분기. 종료 의도("내려줘"·"공유 끝")도 같은 Skill.
model: inherit  # CLAUDE.md §11 — 의도 분류·도구 분기·trade-off 디자이너 친화 번역이 컨텍스트 의존
---

## 목적

디자이너가 작업물을 외부에 공유하려 할 때, *어떻게 공유할지의 trade-off*(보안·외부 의존·지속성)를 디자이너 언어로 번역해 안내하고 가장 적합한 도구 *1개*를 추천·실행. 회사 프로젝트 사고를 사전 게이트로 차단하고, 공유 시점·대상을 자동 기록해 인계와 자연스럽게.

인계(`export-handoff`, *단방향 전달*)와 다름 — 공유는 *양방향 피드백 기대*.

## 발동 / 발동 X

- ✅ "이거 잠깐 보여줘"·"팀에 시안 돌리고 싶어"·"클라이언트한테 보여줄게"·"링크/URL 만들어줘"·"공유"·"배포"
- ✅ 종료: "이제 내려줘"·"그만 보여줘도 돼"·"공유 끝"
- ❌ 단순 저장 → `safe-save`
- ❌ 본인 미리보기 → `preview`
- ❌ 개발자 인계 → `export-handoff`
- ❌ 점검만 → `quality-check`

발동 모호 시 1회 묻기 ("외부에 공유하시려는 거 맞나요? 본인 화면만 보시려면 '보여줘'라고 말씀해주세요").

*외부에 보여줄 의도*가 명확한 발화 — "보여주고 싶어"는 대상이 *외부(클라이언트·팀·상사)*일 때만 발동, 본인 미리보기는 `preview`.

## 처리 흐름

### 1·2. 의도 분류 + Trade-off

`AskUserQuestion` 1회로 4분류 → 선택 직후 trade-off 본문 노출.

```
┌──────────────────┬────────────────────┬───────────────────┬──────────────────┐
│ A 잠깐 (5분~1h)  │ B 단기 (며칠 시안)  │ C 지속 (몇 주)     │ D 공개 (인터넷)   │
├──────────────────┼────────────────────┼───────────────────┼──────────────────┤
│ 임시 통로(터널)   │ 무료 정식 배포      │ 비밀번호 권장       │ 점검 강화 후 공개  │
│ 1분 셋업·회원가입X│ 회원가입 필요       │ B + 지정한 사람만   │ 검색엔진 노출      │
│ 컴터 끄면 사라짐  │ URL 영구·공개 기본   │ 일부 유료 가능      │ 회사면 사전 점검   │
└──────────────────┴────────────────────┴───────────────────┴──────────────────┘
```

질문 문구·trade-off 본문은 [references/intent-tradeoff.md](./references/intent-tradeoff.md).

### 3. 스택 감지

`Read package.json` → STACK 보관 (`import-existing` §1 패턴). 상세 표는 [references/tool-recommend.md](./references/tool-recommend.md) §3.

### 4. 사전 게이트 3중

세 가지 *모두 통과*해야 진입:
- §4.1 빌드 검증 (`auto-validate` 위임)
- §4.2 민감정보 스캔 (`.env`·API key·process.env·회사명 키워드)
- §4.3 더미 데이터 정책 검증

상세 패턴·차단 정책은 [references/share-gates.md](./references/share-gates.md).

### 5·6. 회사 프로젝트 가드 + 외부 의존성 동의

§공유 정책 슬롯 미답변이면 1회 묻고 캐시. *예*면 회사명 키워드 1~3개·INTENT A/B 선택 시 경고. 추천 도구 첫 사용이면 외부 서비스 동의 1회.

문구·캐시는 [references/intent-tradeoff.md](./references/intent-tradeoff.md) §5·§6.

### 7. 도구 추천 + 실행

§3 STACK + §1 INTENT 조합으로 *1개* 추천. *콕 찍어 두지 X* — LLM 시점 판단, 코드에 도구명 하드코딩 X.

도구별 명령 실행 + 진행 가시화 3단계(회원가입·로그인 / 올리는 중 / 끝남) + URL 정형 추출 → `SHARE_URL`·`SHARE_TOOL`.

표·예시는 [references/tool-recommend.md](./references/tool-recommend.md) §7.

*디자이너 발화*에 도구명이 있으면("Vercel로 올려줘") 그 도구 우선 — 이상하면 다른 옵션 1개 + 의견 묻기.

### 8. 사후 처리

#### 8.1 공유 시점 commit (`safe-save` 위임)

`Task` tool로 `safe-save`. 자연어 인자:
> 외부 공유 직전 시점 commit. 메시지: "공유 — <YYYY-MM-DD HH:mm> <대상> (<INTENT 라벨>)"
> 예: "공유 — 2026-04-29 17:32 클라이언트 1차 시안 (B 단기)"

`safe-save`가 자동 한국어 메시지 생성·commit. push는 묻지 않고 로컬만 (외부 공유는 별 작업이라 디자이너 명시 발화 시에만 push). `COMMIT_SHA` 보관.

#### 8.2 §공유 이력 갱신

`CLAUDE.project.md`의 `<!-- kd:slot:share-history -->` 슬롯 표에 1줄 추가 (`Edit` `replace_all: false`):

```markdown
| <YYYY-MM-DD HH:mm> | <INTENT 라벨> | <대상> | <SHARE_URL> | 활성 (`<COMMIT_SHA>`) |
```

대상이 미정이면 묻지 말고 "공유" 한 단어. 슬롯 자체 없으면 (구버전) §인계 주의사항 다음에 새로.

**회전 검사** — append 직후 슬롯 표 본문이 *디자이너가 한눈에 훑을 만함*을 넘었으면 가장 오래된 행들을 `.claude/slot-archive/share-history.md`로 *최신 순 append*하고 슬롯 표에서 그 행 제거. archive 부재 시 함께 생성. archive는 `./CLAUDE.md` `@import`에 미추가(자동 로드 X). 첫 archive 생성 시 1회 안내("이전 공유 이력은 `.claude/slot-archive/share-history.md`로 옮겨두었어요 — *이전 공유 이력 보여줘* 한 마디면 돼요"), 이후 침묵.

`share-history`는 한 행 = 한 공유라 *시간순 짧은 슬롯* — 분량 기준은 갱신 시점 자율(고정 N 박지 X). 정본: `plugin/SCHEMA.md` §2.3. *T3 상태 갱신*(셀만 *활성→종료*)은 회전 트리거 X.

### 9. 응답 (호출 측 톤)

```
**공유** 됐어요 — <SHARE_TOOL>로 올렸어요.

🔗 https://...
   (cmd+클릭 / ctrl+클릭으로 바로 열려요)

이 링크는 <INTENT 톤>:
- A: 내 컴퓨터 켜진 동안만 통해요. 끄거나 절전 들어가면 사라져요.
- B: 항상 접근 가능, URL 안 바뀌어요.
- C: 비밀번호: <도구가 알려주는 값>
- D: 인터넷 누구나 봐요.

그만 보여줘도 될 때 *"이제 내려줘"*라고 하시면 정리해드려요.
```

마지막 다음 행동 1개:
- A: "통화하면서 같이 보실 건가요? 끝나면 *내려줘* 라고만 해주세요."
- B/C: "팀에 링크 보내실 건가요? 보내실 텍스트 함께 정리해드릴까요?"
- D: "공개 전 마지막으로 한번 더 *점검해줘*로 확인하시는 것도 좋아요."

## 종료 분기

T1 활성 공유 식별 → T2 도구별 정리 → T3 이력 상태 갱신 → T4 응답. 상세 동작은 [references/terminate.md](./references/terminate.md).

## Subagent 위임

이 Skill 자체는 *메인 모델 컨텍스트* (`model: inherit`). 의도 4분류·trade-off 번역·도구 추천·민감정보 차단 결정은 *디자인·보안 컨텍스트 의존*이라 다운그레이드 위험.

내부 위임 (격리·정형 도구 사유 충족):
- `auto-validate` (Task, Haiku) — §4.1 빌드 검증. §11 (b)(c)
- `safe-save` (Task, Haiku) — §8.1 공유 시점 commit. §11 (b)(c)
- `error-translator` (메인 가로채기) — 검증·도구 인증·실행 실패 시

이 Skill은 *공유 흐름 오케스트레이션*만. 빌드·commit은 위임, 도구 자체 인증·UI는 도구가 처리.

## 응답 톤

- 한국어 + 페르소나 톤 (`designer-persona`)
- 도구명은 백틱(`Vercel CLI`), 단독 영어는 *<한국어 의미>*(`<영어 원문`) (CLAUDE.user.md §용어 한글 병기)
- 응답 끝 다음 행동 1개
- 외부 공유는 *되돌릴 수 있게* — "그만 보여줘도 될 때 *내려줘*" 한 줄 항상

## 자가 점검

- [ ] §1 의도 4분류 + §2 trade-off (선택지 밖도 가볍게)
- [ ] §4 사전 게이트 3중 모두 통과 (빌드·민감정보·더미)
- [ ] 회사 프로젝트 *예* + INTENT A/B 선택 시 경고 후 동의
- [ ] 도구명 *콕 찍어 두지 X* — LLM 시점 판단, 코드 하드코딩 X
- [ ] §공유 이력 append + 회전(분량 기준 자율)
- [ ] 응답 끝 *"내려줘"* 1줄 항상 + 다음 행동 1개

## 의존

- **다른 Skill**: `auto-validate`(빌드 검증)·`safe-save`(commit)·`error-translator`(회복)·`designer-persona`(톤)·`export-handoff`(인계 시 §공유 이력 자동 첨부)
- **외부 도구**: `Read`/`Glob`/`Grep`(스캔·스택)·`Edit`(슬롯 갱신)·`Bash`(도구별 CLI — `vercel`·`netlify`·`cloudflared`·`ngrok`·`npx serve`)·`Task`(Subagent)·`AskUserQuestion`
- **참조 파일**: `CLAUDE.project.md` (§공유 정책·§더미 데이터 규칙·§공유 이력 슬롯)
