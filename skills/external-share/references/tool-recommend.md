# §3 스택 감지 + §7 도구 추천·실행

## §3. 스택 감지 (`import-existing` §1 패턴 재사용)

`Read` `package.json`(또는 `pubspec.yaml`/`Cargo.toml`) → `dependencies`/`devDependencies` 분석.

| 표지 | 스택 |
|---|---|
| `next` | Next.js |
| `react` + `vite` | React + Vite |
| `expo` 또는 `react-native` | Expo / React Native |
| `vue` / `nuxt` | Vue / Nuxt |
| `astro` | Astro |
| `index.html` 루트 + 빌드 도구 X | 정적 HTML |
| `pubspec.yaml` | Flutter |
| 그 외 | "도구 추천 자동 매칭 X — 옵션만 정리해드릴게요" 분기 |

`STACK = ...` 보관.

## §7. 도구 추천 + 실행

§3 STACK + §1 INTENT 조합으로 도구 *1개* 추천. *콕 찍어 두지 X* — LLM 시점에 가장 적합한 무료·간편 도구. 후보(참고):

| STACK | INTENT A (잠깐) | INTENT B/C/D (정식) |
|---|---|---|
| Next.js / React+Vite / Vue / Astro | `cloudflared tunnel` (무료 영구 URL 가능) 또는 `ngrok` (계정 필요) | Vercel CLI / Netlify CLI / Cloudflare Pages |
| 정적 HTML | 동상 | Netlify Drop / Cloudflare Pages / GitHub Pages |
| Expo | Expo Go QR (도구 자체 생성) | EAS Update |
| Flutter / 기타 | "이 스택은 추천 자동 매칭이 약해요. 옵션 정리해드릴게요" → 후보 2~3개 + trade-off → 사용자 선택 후 명시 동의 → 진행 |

추천 시 *왜 이 도구인지* 1줄 ("Next.js는 *Vercel CLI*가 가장 빠른데, 웹 한 줄 명령으로 끝나요").

도구 *콕 찍지 X* 정책:
- 코드에 도구명 하드코딩 X (이 표는 *참고용 가이드*, LLM이 그 시점 판단)
- *디자이너 발화*에 도구명이 있으면("Vercel로 올려줘") 그 도구 우선 — 이상하면 다른 옵션 1개 + 의견 묻기

## §7.1 실행

도구별 명령은 LLM이 그 시점 표준 명령(`vercel deploy`·`netlify deploy --prod`·`cloudflared tunnel --url ...`). 실행 중 에러는 `error-translator`.

진행 가시화 (디자이너 시야 빈 화면 X):
- "회원가입·로그인 창이 떴어요" / "올리는 중이에요 (1~2분)" / "끝났어요" 3단계
- 완료까지 시간 분 단위

## §7.2 결과 URL 정형 추출

도구 출력에서 URL을 정규식 추출 (`https://[a-zA-Z0-9.-]+\.(vercel\.app|netlify\.app|trycloudflare\.com|...)`). 추출 실패면 도구 출력 마지막 줄들 그대로 + "URL 어느 줄인지 모르겠으면 알려주세요".

`SHARE_URL`, `SHARE_TOOL` 보관.
