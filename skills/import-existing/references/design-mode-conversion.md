# §3-D. 운영 레포 → 디자인 레포 변환 (A 분기 전용)

§0에서 A 판정된 경우만. 핵심 원칙:

> ***prod 경계 코드(`middleware*`·`app/api/**`·`lib/**`·`hooks/**`·`stores/**`)는 절대 분기를 박지 X***.

인증·API 우회는 *별도 모듈에 격리*해 컴포넌트 *import 경로 차원에서만* 분기. 변경은 *별도 commit 단위*로 — 디자이너가 본 레포 반영 시 rebase·revert 쉽게.

## 처리 절차

각 단계 별도 commit 권장 (직접 commit은 §7 뒤 `safe-save` 위임 시점):

### 1. 인증 stub 모듈

`mock/auth-stub.ts` 생성. 진단된 인증 훅(`useAuth`/`useSession`/`useUser` — §4.2에서 발견)의 mock 버전. 반환 형태는 *실제 훅의 타입 시그니처를 따라간다*(`Read`로 추론). 기본 mock 사용자 1명, `loading: false`, `error: null`.

### 2. API stub 모듈

`mock/api-stubs/` 디렉토리. `hasApiRoutes` = true일 때 `app/api/**` 또는 `pages/api/**` 라우트별로 mock 응답 파일. 실제 응답 타입 모르면 `{}`/`[]` + 주석으로 *실 API 응답 구조 추정 필요* 표시.

### 3. 디자인 모드 토글

프레임워크별 환경변수 컨벤션 (휴리스틱):

| 프레임워크 | 토글 변수 |
|---|---|
| Next.js | `NEXT_PUBLIC_KD_DESIGN_MODE === '1'` |
| Vite | `import.meta.env.VITE_KD_DESIGN_MODE === '1'` |
| Expo | `process.env.EXPO_PUBLIC_KD_DESIGN_MODE === '1'` |
| 그 외 | `process.env.KD_DESIGN_MODE === '1'` (커스텀 빌드 시 read 보장 필요 — 응답 안내 1줄) |

`lib/design-mode/index.ts` 신규 — `IS_DESIGN_MODE` 상수만 export. **이 모듈은 *디자인 모드 전용*이고, 이 디렉토리 안 코드는 가드 허용 범위** — `publishing-guard` Skill + hook이 `CLAUDE.project.md` §publishing-boundary 슬롯을 통해 *prod 경계 코드 변경*을 자동 차단·동의·인계 큐 push.

### 4. 환경변수 파일

`.env.kdesigner-design` — 토글 변수 = `1` 한 줄. `.gitignore`에 *추가 X* — *commit해 디자이너 환경에서 그대로 작동*. prod `.env*`는 *건드리지 X*.

### 5. `package.json` scripts 추가

`dev:kd-design` (기존 `dev` 앞에 환경변수 export):
- npm/pnpm: `dotenv -e .env.kdesigner-design -- <기존 dev>` 또는 OS 분기 `<env_var>=1 <기존 dev>`
- 안전한 fallback: `cross-env <var>=1 <기존 dev>` (cross-env 의존성 추가는 *AskUserQuestion 1회*로 동의)

### 6. 에러 노출 차단 레이어 셋업

인증·API stub만으로는 *디자이너 화면에 영어 스택트레이스·빨간 박스가 새는 결*을 다 막지 못함. stub 응답이 실제 응답 형태와 어긋나거나, schema validation이 실패하거나, 컴포넌트가 undefined를 만나면 그대로 화면으로 흘러 디자이너 흐름이 끊긴다. 격리 모듈 옆에 *차단 레이어*를 같은 디자인 모드 전용 경로(`lib/design-mode/**`·`mock/**`) 안에 함께 — prod 경계 코드는 손대지 않으면서 디자이너 화면 앞에 *완충층*.

차단 *방향* (구체 라이브러리·함수는 §1 진단에서 추론한 프레임워크·데이터 fetching·schema validation 스택을 보고 모델이 자율 선택. §1.3 라우트 휴리스틱과 같은 결):

- **페이지 단위 Error Boundary 자연 진입** — 디자인 모드일 때만 자동. 컴포넌트 안 throw도 디자이너 친화 빈/대체 상태로 폴백
- **dev 시점 에러 표시 비활성** — 프레임워크가 띄우는 풀스크린 에러 오버레이·HMR 빨간 박스가 디자인 모드에선 X. 프레임워크별 노출 메커니즘은 모델 추론
- **데이터 fetching 결과의 silent fallback** — 응답 미스매치·undefined·throw가 화면으로 새지 않게 wrapper에서 흡수. wrapper 자체는 *디자인 모드에서만* 활성, prod 경로 영향 X
- **schema validation의 디자인 모드 분기** — validation 실패가 throw로 이어지지 않게. 디자인 모드에선 빈/기본 형태로 폴백

각 차단은 *프로젝트 스택이 그 카테고리를 실제로 쓸 때만*. 디자이너가 첫 페이지 진입 시 영어 스택트레이스 노출 차단이 확인되는 게 셋업 통과 신호. 차단된 에러는 `error-translator`의 브라우저 런타임 경로로 자동 흘려 인지·기록.

### 7. prod 코드는 *손대지 X*

컴포넌트에서 인증·데이터 훅을 import하는 줄을 *명시 동의 후* 다음 패턴으로 변환:

```ts
// 기존: import { useAuth } from '@/hooks/useAuth'
// 변환:
import { useAuth as useAuthProd } from '@/hooks/useAuth'
import { useAuth as useAuthStub } from '@/mock/auth-stub'
import { IS_DESIGN_MODE } from '@/lib/design-mode'
const useAuth = IS_DESIGN_MODE ? useAuthStub : useAuthProd
```

변환 *전*에 `AskUserQuestion` ("이 컴포넌트가 인증 훅을 직접 호출해요. 디자인 모드에서 mock으로 분기할까요?"). 변환은 *컴포넌트 단위*로, *대량 일괄 X*. 디자이너가 만질 페이지부터.

### 8. 변경 *별도 commit*

§7 끝나고 `safe-save` 위임 시 commit 메시지: *"디자인 모드 변환 — 인증·API stub 격리(`lib/design-mode/`·`mock/auth-stub.ts`·`mock/api-stubs/`), 에러 노출 차단 레이어, `dev:kd-design` 추가"*. 이후 컴포넌트 분기 변경은 *다음 commit*.

### 9. 결과 기록

`CLAUDE.project.md` §design-mode-config 슬롯에 박기 (§7 참조). 기본 셋업(토글·mock 경로·dev 스크립트·환경변수) 외에 *차단 레이어 셋업 상태*도 같은 슬롯에 자연 누적 — 어떤 카테고리(페이지 Error Boundary·dev 시점 오버레이 비활성·데이터 fetching wrapper·schema validation 분기)가 실제 셋업됐는지 *방향 표현*으로 한 줄씩(특정 라이브러리명 박지 X). 인계 시 개발자가 *무엇이 격리됐고 무엇이 노출 차단됐는지* 한눈에. §publishing-boundary 슬롯은 *템플릿 기본값 그대로* 두기(빈 골격) — 사용자/개발자가 본 레포 구조 보고 수정 가능. 기본값은 hook이 직접 적용하므로 비어있어도 가드 동작.
