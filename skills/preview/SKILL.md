---
description: |
  화면 즉시 확인 — 의존성 설치(필요 시) + dev 서버 시작 + 브라우저 자동 오픈을 한 번에. 포트 충돌은 `error-translator`로 위임해 다른 포트 자동 재시도. Claude Desktop App 환경 우선 감안.

  발동 예시 (사용자 자연어):
  - "보여줘", "지금까지 작업 보여줘"
  - "실행해줘", "한번 띄워봐"
  - "화면 켜줘"

  사용 시점: 디자이너가 만든 화면을 즉시 확인하고 싶을 때. 의존성·서버·브라우저 단계 자체를 의식하지 않게.
model: inherit  # CLAUDE.md §11 — Haiku 200k 한도가 import-existing 직후 *부모 컨텍스트 무거움*과 충돌(이슈 #3). 정형 명령만 보면 다운그레이드 정당화되나, 진입 자체가 막히면 가치 0이라 inherit 우선.
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

### 5.5. 브라우저 런타임 모니터링 — 디자이너 *앞에서* 가로채기

서버 stdout/stderr는 `error-translator`가 이미 가로채지만, *브라우저 화면 안*에서 일어나는 런타임 에러(컴포넌트 throw, 데이터 미스매치, 프레임워크의 풀스크린 에러 오버레이, console.error 폭주 등)는 stdout 사각지대 — 디자이너가 *영어 스택트레이스나 빨간 박스를 먼저 보게 되는 결*이 가장 위험. 디자이너 발화(`"빨간 박스 떴어"`)는 *fallback* 경로로 남기고, *메인이 먼저 알아채는* 자동 경로를 우선으로 둔다.

*어떤 메커니즘*으로 브라우저 런타임을 들여다볼지는 *환경 자율 선택* — 사용 가능한 도구(브라우저 자동화 MCP, dev 서버 stdout이 클라이언트 콘솔까지 forward하는지 여부, 프레임워크의 자체 에러 reporting hook 등)와 프로젝트 스택을 보고 가장 가벼운 경로를 모델이 고른다. *결정론적 메커니즘 매트릭스는 박지 X* — 환경마다 사용 가능한 것이 다르고, 사용 불가능한 메커니즘을 강제하면 진입 자체가 막힘.

방향:
- 브라우저 오픈 후 *짧은 관찰 창*(첫 화면 진입까지) 동안 *콘솔 에러 패턴* 또는 *프레임워크 에러 오버레이 표시* 감지
- 감지되면 디자이너 응답으로 흘리기 *전에* `error-translator` 브라우저 런타임 경로로 위임 — 친화 가공은 거기서
- 감지가 *불가능한 환경*(브라우저 자동화 도구 부재 + dev 서버가 클라이언트 콘솔 forward X)이면 이 단계는 *조용히 스킵*. 디자이너 발화 fallback 경로는 그대로 유효
- 차단 인프라(`import-existing` §3-D §6 에러 노출 차단 레이어)가 셋업된 프로젝트면 *상당수가 차단 레이어에서 이미 흡수*되어 모니터링까지 도달 X. 모니터링은 *차단을 뚫고 새는 케이스*만 잡는 안전망

`import-existing` A 분기로 셋업된 프로젝트는 `CLAUDE.project.md` §design-mode-config의 차단 레이어 상태로 *어떤 카테고리가 흡수 책임*인지 확인 가능. 셋업 안 된 프로젝트(B/C/D 분기 또는 `new-service`)면 차단 레이어 없이 *모니터링이 1차 안전망*이라는 결을 인지하고 동작.

### 6. 응답 가공 (호출 측 톤)
정형 결과를 메인이 페르소나 톤으로 가공.

응답 패턴 (성공):
> **화면 출력 통로**(`port 3000`)에 화면을 띄웠어요 — 브라우저 창에 곧 뜰 거예요. (만약 안 뜨면 `http://localhost:3000` 으로 직접 들어가도 돼요.)

포트 변경된 경우:
> **3000번 통로**가 다른 작업에 쓰이고 있어서 **3001번 통로**로 바꿔서 띄웠어요 — `http://localhost:3001`

## Subagent 위임
- **이 Skill 자체는 `inherit`** (CLAUDE.md §11)
  - 의존성 설치·서버 시작은 정형 명령이라 다운그레이드 후보였으나, `import-existing` 직후 호출되는 패턴이 흔해 *부모 컨텍스트(코드베이스 인덱싱 + 매뉴얼)가 Haiku 200k 한도를 넘기는 케이스*가 실측됨(이슈 #3).
  - Skill 진입 자체가 막히면 디자이너 흐름이 끊겨 *Skill 가치 0*. 정형 명령 다운그레이드 이득보다 진입 보장이 우선.
- 포트 충돌·네트워크 오류는 `error-translator`로 위임 (메인 가로채기 + 자동 회복)
- *브라우저 런타임 에러*(§5.5 모니터링 감지분)도 `error-translator`의 브라우저 런타임 경로로 자동 위임 — 디자이너 발화는 fallback
- 향후 `import-existing` 종료 시 `fresh-session-guide`로 자연스러운 새 대화 권유가 정착되면, 부모 컨텍스트 무거움 케이스가 줄어 다시 다운그레이드 검토 가능.

## 응답 톤
- 한국어, 응답 끝 다음 행동 1개 제안 (`designer-persona` 글로벌 원칙)
- `port`/`localhost` 등 영어 토큰은 한국어 병기 후 백틱
- 서버 시작 중 진행 안내는 1줄로 — "준비 중이에요" 정도, 내부 단계 풀어 설명 X

## 의존
- 다른 Skill: `error-translator` (포트·네트워크·의존성 회복), `designer-persona` (톤), `new-service` (셋업 직후 호출)
- 외부 도구: `Bash` (`lsof`, `ps`, 패키지 매니저, dev 서버, `open`/`xdg-open`/`start`), `Read` (`package.json`, lockfile)
- 참조: PRD §5 preview, CLAUDE.md §8 에러 자동 회복
