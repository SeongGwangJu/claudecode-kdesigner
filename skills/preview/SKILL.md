---
description: |
  화면 즉시 확인 — 의존성 설치(필요 시) + dev 서버 시작 + 브라우저 자동 오픈을 한 번에. 포트 충돌은 `error-translator`로 위임해 다른 포트 자동 재시도. Claude Desktop App 환경 우선 감안.

  발동 예시 (사용자 자연어):
  - "보여줘", "지금까지 작업 보여줘"
  - "실행해줘", "한번 띄워봐"
  - "화면 켜줘"

  사용 시점: 디자이너가 만든 화면을 즉시 확인하고 싶을 때. 의존성·서버·브라우저 단계 자체를 의식하지 않게.
model: haiku
---

## 목적
디자이너가 만든 화면을 한 번의 자연어로 띄워준다. 의존성 설치·서버·브라우저 단계가 디자이너 시야에 등장하지 않게 하는 것이 핵심.

## 발동 조건

### 발동
- "보여줘"/"실행해줘"/"띄워봐" 류 자연어
- `new-service` 셋업 직후 자동 호출 (첫 화면 확인)

### 발동 X
- 빌드 검증만 원할 때 → `auto-validate`
- 점검·품질 확인 → `quality-check`

## 처리 흐름

### 1. 기존 서버 감지 — 살아있으면 브라우저만
서버가 이미 떠 있으면 새로 띄우지 않는다(포트 충돌·서버 깨짐 방지).

판정:
- `lsof -i :3000`/`:5173`/`:4321`/`:8081` 등 일반 dev 포트
- `ps`에 `next dev`/`vite`/`astro dev`/`expo start` 등

서버 살아있음 → 해당 포트 URL로 브라우저 오픈만 하고 §5로.

### 2. 의존성 설치 (필요 시)
`node_modules` 부재 또는 `package.json` 변경 후 미설치 감지 시 자동 설치 (CLAUDE.md §8).

패키지 매니저 추론 (lockfile 기준):

| Lockfile | 명령 |
|---|---|
| `pnpm-lock.yaml` | `pnpm install` |
| `yarn.lock` | `yarn install` |
| `bun.lockb` | `bun install` |
| 그 외 | `npm install` |

설치 실패 시 `error-translator`로 위임 (네트워크·권한 등 자동 회복).

### 3. dev 서버 시작
`package.json` `scripts.dev` 우선:

| 우선순위 | 키 | 동작 |
|---|---|---|
| 1 | `dev` | 표준 |
| 2 | `start` | dev 없을 때 fallback |
| 3 | 직접 명령 (Next: `next dev` / Vite: `vite` / Astro: `astro dev`) | scripts 둘 다 없을 때 |

호출 명령은 §2와 동일한 패키지 매니저 추론.

서버는 `Bash` `run_in_background: true`로 시작. 시작 후 *포트가 listen 상태가 될 때까지* 짧게 폴링 (`lsof` 또는 `curl -sf` ~5초 상한, sleep 루프 X — 한 번 체크 후 늦으면 더 기다린다고 안내).

### 4. 포트 충돌 → error-translator 위임
`EADDRINUSE` 또는 `port .* already in use` 감지 시 `error-translator`가 다른 포트(3001, 3002, ...)로 재시도. 환경변수 `PORT`로 주입.

### 5. 브라우저 자동 오픈
시작된 URL을 OS 기본 브라우저로 연다.

| 환경 | 명령 |
|---|---|
| macOS | `open http://localhost:<port>` |
| Linux | `xdg-open http://localhost:<port>` |
| Windows | `start http://localhost:<port>` |

Claude Desktop App 환경에서는 백그라운드 서버 + 외부 브라우저 조합이 가장 안정. CLI에서는 동일.

### 6. 응답 가공 (호출 측 톤)
정형 결과를 메인이 페르소나 톤으로 가공.

응답 패턴 (성공):
> **화면 출력 통로**(`port 3000`)에 화면을 띄웠어요 — 브라우저 창에 곧 뜰 거예요. (만약 안 뜨면 `http://localhost:3000` 으로 직접 들어가도 돼요.)

포트 변경된 경우:
> **3000번 통로**가 다른 작업에 쓰이고 있어서 **3001번 통로**로 바꿔서 띄웠어요 — `http://localhost:3001`

## Subagent 위임
- **이 Skill 자체가 Haiku Subagent로 동작** (`model: haiku`)
- 의존성 설치 + 서버 시작은 정형 명령, Haiku로 충분
- 포트 충돌·네트워크 오류는 `error-translator`로 위임 (메인 가로채기 + Haiku 회복)
- PRD §12 라우팅 표 일치

## 응답 톤
- 한국어, 응답 끝 다음 행동 1개 제안 (`designer-persona` 글로벌 원칙)
- `port`/`localhost` 등 영어 토큰은 한국어 병기 후 백틱
- 서버 시작 중 진행 안내는 1줄로 — "준비 중이에요" 정도, 내부 단계 풀어 설명 X

## 의존
- 다른 Skill: `error-translator` (포트·네트워크·의존성 회복), `designer-persona` (톤), `new-service` (셋업 직후 호출)
- 외부 도구: `Bash` (`lsof`, `ps`, 패키지 매니저, dev 서버, `open`/`xdg-open`/`start`), `Read` (`package.json`, lockfile)
- 참조: PRD §5 preview, CLAUDE.md §8 에러 자동 회복
