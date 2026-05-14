# §4. 사전 게이트 3중

세 가지가 *모두 통과*해야 §5로 진입. 하나라도 실패 = 차단·자동 회복 시도.

## §4.1 빌드 검증 — `auto-validate` 위임

`Task` tool로 `auto-validate` Subagent. *build script 우선* 명시:

> 외부 공유 직전 검증입니다. `build` script가 있으면 그것까지 돌려주세요(dev 서버 죽어있을 때만). 빈 화면·500 에러로 외부에 나가면 안 됩니다.

분기:
- `status: pass` → 통과
- `status: skipped` → 진행 + 응답 1줄 ("이 프로젝트는 빌드 검증 환경이 없어 그대로 진행했어요")
- `status: fail` → `error-translator`. 자동 회복 성공 시 재검증, 실패 시 두 블록 패턴 + *공유 중단*

## §4.2 민감정보 스캔

회사 프로젝트 사고 1순위 차단점. `Glob`+`Grep`:

| 패턴 | 의미 | 처리 |
|---|---|---|
| `.env`, `.env.local`, `.env.*` | 환경 변수 파일 존재 | `.gitignore`에 포함됐는지 — 빠져있으면 *차단* |
| `(sk\|ghp\|gho\|glpat\|xox[bp])[_-][A-Za-z0-9_-]{16,}` | 흔한 API key prefix (OpenAI `sk-...`·GitHub `ghp_...`·GitLab `glpat-...`·Slack `xoxb-...`). prefix 다음 하이픈·언더스코어 양쪽 허용 | 어느 파일이든 발견 시 *차단* |
| `process\.env\.[A-Z_]+` | 클라이언트 코드에 환경변수 직접 참조 | Next.js의 `NEXT_PUBLIC_*` 외 패턴이면 경고 (공개 빌드에 박힘) |
| `CLAUDE.project.md` §공유 정책 회사명 키워드 | 사전 등록된 회사 내부명 | 발견 시 *차단* + 어느 파일·줄 |

검출 시:
- *차단* — 어느 파일 어느 줄
- *자동 마스킹 X* — 디자이너에게 결정권 ("이 정보를 제거하거나 .gitignore에 넣고 다시 시도해주세요")
- 회사명 키워드 미설정이면 §5 회사 가드에서 묻고 캐시

스캔 범위: `git ls-files` 또는 staged + tracked + untracked(gitignore 제외). `node_modules/`·`.next/`·`dist/`·`build/` 제외.

## §4.3 더미 데이터 정책 검증

`CLAUDE.project.md` §더미 데이터 규칙과 실제 코드 매칭:

- `mock/` 폴더 안 데이터 분리됐는지
- 컴포넌트 안 *하드코딩된 데이터*(배열·객체 리터럴 큰 덩어리)
- 검출 시 *경고만* — 차단 X (디자이너 의도일 수도)
- 회사 프로젝트(§5 = 예)면 *경고 → 확인 질문* 격상

검출 결과는 §8 응답에 함께.
