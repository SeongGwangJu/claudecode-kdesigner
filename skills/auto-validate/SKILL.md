---
description: |
  저장 직전·큰 작업 마무리 시 자동 검증. **환경 인식 wrapper** — 직접 lint/build 명령 박지 X. 프로젝트 `package.json` scripts(`lint`/`typecheck`/`check`/`build`) 우선 호출, 없으면 일반 fallback. dev 서버 살아있으면 빌드 회피, lint·타입만. 결과는 정형 출력으로 호출 측 Skill에 반환.

  발동 예시 (사용자 자연어):
  - 다른 Skill (`safe-save` 등) 호출 직전 자동 트리거
  - 큰 작업 (컴포넌트 추가, 구조 변경) 마무리 시
  - "한번 돌려봐", "에러 없어?", "빌드 해봐"

  사용 시점: 저장 직전, 큰 작업 마무리. 텍스트 사소한 변경(레이블·문구만)엔 발동 X.
model: haiku
---

## 목적
정형 검증을 환경 인식 wrapper로 실행한다. 프로젝트가 가진 scripts를 우선 따라가며, 없을 때만 일반 fallback. *우리가 통제하는 영역은 셋업 시 scripts 박기까지* — 이 Skill은 그걸 호출만 한다.

## 발동 조건

### 발동
- 다른 Skill에서 호출
  - `safe-save` 호출 직전 (저장 직전 검증)
  - `new-service`/`import-existing` 셋업 직후 (큰 작업 마무리)
- 사용자 자연어
  - "한번 돌려봐", "에러 없어?", "빌드 해봐"

### 발동 X
- 텍스트 사소한 변경 (레이블·문구만, 변경 라인 수 < 5)
- `mock/` 가짜 데이터 변경만
- `asset/` 자산 추가만
- 사용자가 "그냥 넘어가" 명시

판단 보조: 변경 라인 수·파일 종류·파일 개수로 *큰 작업*인지 추정 (CLAUDE.md §9).

## 처리 흐름

### 1. dev 서버 프로세스 감지
빌드는 dev 서버를 깰 수 있다. 살아있으면 lint·타입만 한다.

판정 기준:
- `lsof -i :3000`/`:5173`/`:4321` 등 일반 dev 포트
- `ps` 출력에 `next dev`, `vite`, `astro dev`, `expo start` 등

```
서버 살아있음 → lint + typecheck만, build 스킵
서버 죽어있음 → lint + typecheck + (필요 시) build
```

### 2. 환경 인식 — `package.json` scripts 우선

`Read` `package.json` → `scripts` 객체 확인. 우선순위:

| 순위 | 키 (별칭 포함) | 동작 |
|---|---|---|
| 1 | `check` | 통합 체크 — 있으면 이 하나로 끝 |
| 2 | `lint` | 린트 |
| 2 | `typecheck` / `type-check` / `tsc` | 타입 검사 |
| 3 | `build` | dev 서버 죽어있을 때만 |

호출 명령은 lockfile로 패키지 매니저 추론:

| Lockfile | 명령 |
|---|---|
| `pnpm-lock.yaml` | `pnpm run <script>` |
| `yarn.lock` | `yarn <script>` |
| `bun.lockb` | `bun run <script>` |
| 그 외 (`package-lock.json` 또는 없음) | `npm run <script>` |

### 3. Fallback (scripts 없을 때)
1차 검증 환경의 *셋업 책임*은 `new-service` Skill이 진다 (scripts 박기). 외부에서 가져온 프로젝트는 비어 있을 수 있어 fallback:

- `tsconfig.json` 존재 → `npx tsc --noEmit`
- `eslint.config.*` 또는 `.eslintrc.*` 존재 → `npx eslint .`
- 둘 다 없음 → 검증 스킵 + 호출 측에 `status: skipped, reason: no-validation-env` 보고

### 4. 결과 정형 출력
이 Skill은 **사용자에게 직접 응답하지 않는다**. 호출 측(`safe-save` 등)이 디자이너 톤으로 가공한다.

정형 결과 형식 (Task 반환값):
```
status: pass | fail | skipped
ran: [lint, typecheck]
skipped: [build]            # 이유: dev 서버 살아있음
duration_ms: 4321
errors:                     # fail 시에만
  - file: components/Button.tsx:42
    raw: <stderr 원문>
```

### 5. 실패 시 위임
`status: fail`이면 stderr 원문을 호출 측 Skill이 받아 `error-translator`로 위임한다 (자동 회복 가능한 분류면 거기서 처리).
이 Skill 자체는 *번역하지 않고 원문만 정형 결과에 실어 반환* — 책임 분리.

## Subagent 위임
- **이 Skill 자체가 Haiku Subagent로 동작** (`model: haiku`)
- 호출 측 Skill (`safe-save` 등)이 메인 모델에서 `Task` tool로 본 Skill을 위임 호출
- 본 Skill 내부에서 추가 위임 X — 단일 책임(검증 실행 + 정형 출력)
- PRD §12 라우팅 표 일치

## 응답 톤
- **사용자 직접 노출 X** — 정형 입출력만
- 호출 측 Skill이 페르소나 톤으로 가공해 디자이너에게 전달

## 의존
- 다른 Skill: `safe-save`/`new-service`/`import-existing` (호출 측), `error-translator` (실패 시 호출 측이 위임)
- 외부 도구: `Bash` (`lsof`, `ps`, `npm/pnpm/yarn/bun run`, `tsc`, `eslint`), `Read` (`package.json`, lockfile)
- 셋업 의존: `new-service`가 `lint`/`typecheck` scripts를 박아두는 책임 짐 (CLAUDE.md §9)
- 참조: PRD §5 auto-validate, CLAUDE.md §9
