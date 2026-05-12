# CLAUDE.project.md Placeholder 기본값 매핑

> `new-service`가 빈 디렉토리에서 셋업 후 `CLAUDE.project.md` placeholder를 *질문 없이* 자동 채우는 기본값. 결정 피로 최소화 — 사용자가 화면 만들면서 자연스럽게 채울 수 있게 *일단 시작*.

## 기본값 표

| 필드 (placeholder) | 기본값 | 사용자 사후 변경 |
|---|---|---|
| `{{서비스명}}` | 폴더 이름 (`basename "$PWD"`) | ✓ |
| `{{서비스 목적}}` | "(아직 정해지지 않음 — 화면 만들면서 자연스럽게 채워질 거예요)" | ✓ |
| `{{사용자층}}` | "(아직 정해지지 않음)" | ✓ |
| `{{스택}}` | 선택한 스택 (Next.js + Tailwind + shadcn/ui 등) | — (셋업 결과) |
| `{{디자인 시스템 토큰}}` | shadcn 기본 토큰 (color·radius·spacing 기본값 그대로) | ✓ |
| `## 사용 가능한 컴포넌트` | shadcn으로 박은 `Button`·`Card`·`Input` 한 줄씩 | 자동 갱신 (`design-system-guard`) |

## 처리 원칙

1. **placeholder가 비어 있는 채로 둬도 동작은 한다** — 디자이너가 화면 만들면서 채울 수 있게 *질문하지 않고 일단 시작*.
2. **이미 채워진 슬롯은 덮지 않음** — `import-existing` 시 추출된 값이 있으면 그쪽 우선.
3. **자동 갱신 슬롯**은 `design-system-guard`가 컴포넌트 변경 감지 시 갱신. 사용자가 직접 손대지 않음.
4. **글로벌 미학 학습 슬롯이 채워져 있으면 시드** — 전역 `~/.claude/CLAUDE.md` §미학 학습의 자동 누적 슬롯(`avoidance`·`tone-extracted`)이 있으면 해당 프로젝트 슬롯에 *원문 그대로* 시드 (`new-service` §7.1 참조). 디자이너 셋업 의식에서 *입력 질문은 없다*.

## 슬롯 ID 매핑

`CLAUDE.project.md`의 placeholder는 슬롯 마커로 식별:

| placeholder | 슬롯 ID | 빈 골격 카테고리 |
|---|---|---|
| 디자인 철학 | `design-philosophy` | 빈 골격 |
| 톤 한 단어 | `project-tone` | 빈 골격 |
| 레퍼런스 | `project-references` | 빈 골격 |
| 회피 (프로젝트) | `project-avoidance` | 자동 누적 (`feedback-curator`) |
| 핵심 토큰 | `design-tokens` | 빈 골격 |
| 사용 스택 | `tech-stack` | 빈 골격 |
| 사용 가능한 컴포넌트 | `components` | 자동 관리 |
| 마지막 작업 | `last-work` | 자동 갱신 (`fresh-session-guide`) |

전체 슬롯 정의는 `plugin/SCHEMA.md` §2.2.
