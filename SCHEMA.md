# Plugin Schema — 마커·슬롯·표준 키 단일 진실

> 이 문서는 *교차 검증용*입니다. SKILL은 디자인초기설정.md §6.0 자급식 manifest 패턴을 임베드한 채 유지합니다(디자이너 환경에서 외부 templates resolve 실패 회피용).
>
> 작업 시 SKILL과 이 문서의 불일치가 발견되면, **SKILL의 임베드된 manifest가 진실**이고 이 문서는 그에 맞춰 갱신합니다.

---

## 1. 마커 패턴

### 1.1 디자이너 모드 격리 마커
`./CLAUDE.md` 또는 `~/.claude/CLAUDE.md`에서 *플러그인이 추가한 영역*을 격리:

```
<!-- kd:designer-mode:start -->
... (이 사이만 /kdesigner:디자인끄기가 잘라 복원)
<!-- kd:designer-mode:end -->
```

- 정확히 1쌍이어야 정상 (0쌍 또는 2쌍 이상 = 손상)
- 사용자 원본은 마커 *밖*에만 있어야 함 — 내부는 플러그인 관리 영역

### 1.2 슬롯 마커
`CLAUDE.user.md`(전역 영역) 또는 `CLAUDE.project.md`(프로젝트) 안에서 각 슬롯을 정확히 식별:

```
<!-- kd:slot:<ID> -->
## 한국어 헤더 (또는 ###)
> 안내 인용구
... 본문 ...
```

- 마커 ID + 한국어 헤더 둘 다 정확히 1번씩 등장
- 같은 ID 2번 이상 또는 헤더 2번 이상(마커 0개) = 손상 의심 → 마이그레이션 중단(디자인초기설정.md §6.5)

---

## 2. 슬롯 ID 표

### 2.1 전역(`~/.claude/CLAUDE.md`) 슬롯 — `kd:designer-mode:start`/`end` 마커 격리 블록 안

| ID | 한국어 헤더 | 카테고리 | 빈 골격 |
|---|---|---|---|
| `designer-profile` | `## 디자이너 프로필 (이 사용자의 미학 정체성)` | 컨테이너 | 헤더 + 안내 인용구만 |
| `fav-references` | `### 좋아하는 디자인 / 레퍼런스` | 답 필요 | placeholder 3줄 (`{{레퍼런스 N}} — {{왜 좋았는지}}`) |
| `portfolio` | `### 본인 대표 작업` | 답 필요 | `{{포트폴리오 URL 또는 "공개 URL 없음"}}` |
| `avoidance` | `### 피하고 싶은 디자인 (자동 누적 슬롯)` | 자동 누적 | `{{사후 누적 N}}` placeholder |
| `tone-extracted` | `### 평소 톤 (자동 추출 슬롯)` | 자동 추출 | 톤/폰트/공간감 placeholder 3줄 |

진실 위치: `plugin/templates/CLAUDE.user.md`.

### 2.2 프로젝트(`./CLAUDE.project.md`) 슬롯

| ID | 한국어 헤더 | 카테고리 | 비고 |
|---|---|---|---|
| `design-philosophy` | `### 철학` | 빈 골격 | 1~3줄 placeholder |
| `project-tone` | `### 톤 한 단어` | 빈 골격 | `aesthetic-guard`가 가장 먼저 읽는 슬롯 |
| `project-references` | `### 레퍼런스` | 빈 골격 | placeholder 2줄 |
| `project-avoidance` | `### 피하고 싶은 디자인 (이 프로젝트 한정)` | 빈 골격 | `feedback-curator` 누적 위치 |
| `design-tokens` | `### 핵심 토큰` | 빈 골격 | 색·간격·둥글기·타이포 |
| `tech-stack` | `## 사용 스택` | 빈 골격 | — |
| `share-policy` | `## 공유 정책 (자동 관리)` | 자동 관리 | `external-share` 갱신 |
| `components` | `## 사용 가능한 컴포넌트` | 자동 관리 | `import-existing` 첫 생성, `design-system-guard` 갱신 |
| `share-history` | `## 공유 이력` | 자동 관리 | `external-share` 갱신, `export-handoff` 참조 |
| `last-work` | `## 마지막 작업` | 자동 갱신 | `fresh-session-guide` 갱신 |

진실 위치: `plugin/templates/CLAUDE.project.md`.

---

## 3. `package.json` scripts 표준 키 (auto-validate 인터페이스)

`auto-validate` Skill은 다음 키를 *우선 호출*. 누락 시 fallback. 표준 키 박는 책임자: `new-service` (셋업 시), `import-existing` (가져올 때 — 충돌 시 건드리지 않음).

| 키 | 우선 호출 | 일반 fallback |
|---|---|---|
| `lint` | `next lint` (Next) / `eslint .` (그 외) | `npx eslint .` |
| `typecheck` | `tsc --noEmit` | `npx tsc --noEmit` |
| `check` | (있으면 lint+typecheck 묶음) | 박지 않음 — 사용자 후행 박기 |
| `dev` | (프레임워크별 표준) | — |
| `build` | (프레임워크별 표준) | — |

**주의**: `tsc --noEmit`은 `tsconfig.json`이 있어야 작동. 없으면 `npx tsc --init` 선행.

---

## 4. `.claude/.kd-session-base` SHA 기록 — 책임자 3곳

`export-handoff`가 `git diff $BASE_SHA..HEAD`로 사이클 변경분을 추릴 때 기준점.

**박는 책임자** (3곳 — 처음 박는 1회만, 이미 있으면 덮어쓰지 X):
- `commands/디자인초기설정.md` §4.1 — 플러그인 모드 켤 때 처음 박음
- `skills/new-service/SKILL.md` §8 — 빈 디렉토리 셋업 후 첫 commit 직후
- `skills/safe-save/SKILL.md` §0 — 첫 저장 시점에 안전망(다른 흐름이 안 박았을 때)

**.gitignore 처리**: `.claude/.kd-session-base` 한 줄을 자동 추가 (없으면 새로 만들고 그 한 줄만). `.claude/` 디렉토리 자체는 ignore X.

**git 저장소 아닌 경우**: 스킵 (3곳 모두 동일 처리).

---

## 5. Skill 트리거 충돌 처리

겹치는 자연어 발화 라우팅 — 각 SKILL 본체 §트리거 충돌 처리에 동일 표 박혀 있음:

| 발화 패턴 | 우선 SKILL | 근거 |
|---|---|---|
| "이 색 좀 부드럽게", "둥글기 키워줘", 토큰 변경 의도 | `design-system-guard` | 토큰 일관성 우선 |
| "랜딩 만들어줘", "프로필 페이지", 화면 생성·구도 결정 | `aesthetic-guard` | 미학 결정 |
| "너무 흔해 보여", "Linear/Notion처럼 X말고", 부정 신호 누적 | `feedback-curator` | 누적·전역 승격 |
| "이미지 추가", "아바타 박아줘", 이니셜 박스 회피 | `aesthetic-guard` | AI slop 강한 신호 |
| "저장해줘", "임시저장" | `safe-save` | commit 책임 |
| "보여줘", "띄워줘" | `preview` | dev 서버 책임 |
| "점검해줘", "확인해줘" | `quality-check` | 정적 분석 책임 |
| "개발자한테 넘기기" | `export-handoff` | 인계 README 책임 |

---

## 6. References 위치 표

플러그인이 사용하는 `references/*.md` lazy load 자료 — `${CLAUDE_SKILL_DIR}/references/<file>.md` 절대경로로 SKILL 본체에서 참조.

| 위치 | 용도 |
|---|---|
| `skills/aesthetic-guard/references/finishing-checklist.md` | 출력 직전 마감 디테일 (8개 본체 외 추가 표준) |
| `skills/aesthetic-guard/references/ai-slop-vocab.md` | AI slop 어휘·한국어 슬롭 형용사·질문 패턴 |
| `skills/new-service/references/init-scripts-schema.md` | `package.json` scripts 표준 키 (이 SCHEMA §3와 정합) |
| `skills/new-service/references/placeholder-defaults.md` | `CLAUDE.project.md` placeholder 기본값 |
| `commands/references/tool-check-messages.md` | 디자인초기설정 §0 도구 누락 안내 메시지 |

---

## 7. 자급식 manifest 임베드 패턴

디자인초기설정.md §6.0(line 325-354)이 *외부 templates resolve 실패 회피용*으로 manifest를 임베드한 패턴. 다른 SKILL도 동일 패턴 따름:

- 슬롯 schema 변경 시 → `templates/CLAUDE.user.md`·`templates/CLAUDE.project.md`·`디자인초기설정.md §6.0`·이 SCHEMA §2.1·§2.2 *5곳을 함께 갱신*
- SKILL 임베드는 *진실 사본*이지 외부 lookup이 아님 (디자이너 환경에서 templates 경로 resolve 실패해도 SKILL이 자급으로 동작)
- 이 SCHEMA는 *작업자(개발자) 교차 검증용* — SKILL과의 불일치 발견 시 SKILL을 진실로 두고 SCHEMA 갱신
