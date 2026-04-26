---
description: |
  새 서비스 0→1 셋업. 웹/앱 묻고 기본 추천 스택(웹: Tailwind+shadcn/ui+Next.js / 앱: Expo+NativeWind)으로 폴더 구조 생성, CLAUDE.project.md placeholder 채워넣기. package.json scripts에 lint/typecheck 보장.

  발동 예시 (사용자 자연어):
  - "새 디자인 시작할게"
  - "새로 만들고 싶어"
  - "처음부터 만들어줘"

  사용 시점: 빈 디렉토리 또는 새 프로젝트 시작 의도. 기존 코드 있으면 `import-existing` 권장.
model: sonnet
---

## 목적
30분 안에 새 서비스 0→1 셋업. 결정 피로 최소화 (기본 추천 우선).

## 발동 조건
- 발동: 새 서비스 시작 자연어
- 발동 X: 기존 프로젝트 작업 (그땐 `import-existing`)

## 처리 흐름
> ⚠️ Phase 5 placeholder. 본 로직은 Phase 5에서 작성.
> 핵심:
> 1. AskUserQuestion: 웹/앱? "잘 모르겠어요" 옵션 → 기본 추천 (웹 + Tailwind/shadcn/Next.js)
> 2. 폴더 구조 생성 (`asset/`, `mock/`, `components/`)
> 3. `CLAUDE.project.md` placeholder 채워넣기 (서비스명·사용자층 등)
> 4. `package.json` scripts에 `lint`/`typecheck` 보장 (auto-validate가 호출할 표준 키)

## Subagent 위임
- 본 Skill 자체가 Sonnet Subagent (결정 흐름 + 셋업, 중간 난이도)

## 응답 톤
- 한국어, 비유, 다음 행동 1개 제안 (글로벌 원칙)
- 한 사이클 질문 3회 상한 (CLAUDE.md §6)

## 의존
- 다른 Skill: `auto-validate` (셋업 후 검증), `designer-persona`
- 외부 도구: Bash (npm/pnpm init), Write (폴더·파일 생성), AskUserQuestion
