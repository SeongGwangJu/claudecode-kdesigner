---
description: |
  의존성 설치 + dev 서버 시작 + 브라우저 자동 오픈. Claude Desktop App 환경 감안. 포트 충돌 시 자동 다른 포트로 재시도.

  발동 예시 (사용자 자연어):
  - "보여줘"
  - "지금까지 작업 보여줘"
  - "실행해줘"
  - "한번 띄워봐"

  사용 시점: 디자이너가 만든 화면을 즉시 확인하고 싶을 때.
model: haiku
---

## 목적
디자이너 화면 즉시 확인 — 의존성 설치 + dev 서버 + 브라우저 오픈을 한 번에.

## 발동 조건
- 발동: 보여달라/실행하라 자연어
- 발동 X: 빌드만 원할 때 (그땐 `auto-validate`)

## 처리 흐름
> ⚠️ Phase 4 placeholder. 본 로직은 Phase 4에서 작성.
> 핵심:
> 1. 의존성 설치 (필요 시) — 누락 → 자동 설치 (CLAUDE.md §8)
> 2. dev 서버 켜기 — 포트 충돌 → 다른 포트로 재시도 (`error-translator` 위임)
> 3. 브라우저 자동 오픈 (Desktop App 환경 감안)

## Subagent 위임
- 본 Skill 자체가 Haiku Subagent (의존성 설치 + 서버 켜기, 정형 명령)

## 응답 톤
- 한국어, "준비 중..." → "켰어요 → http://localhost:..." 비유
- 다음 행동 1개 제안 (글로벌 원칙)

## 의존
- 다른 Skill: `error-translator` (실패 회복)
- 외부 도구: Bash (`npm run dev` 등 환경 인식 호출)
