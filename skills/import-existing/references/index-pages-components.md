# §4. 컴포넌트 + §4.5 페이지 인덱싱

이 Skill의 *핵심 산출물*. `CLAUDE.project.md` §components·§pages 슬롯 일괄 생성.

## §4. 컴포넌트 스캔

### §4.1 발견

`Glob`으로 `components/**/*.{tsx,jsx}`·`src/components/**/*.{tsx,jsx}`·`app/**/*.{tsx,jsx}` 중 컴포넌트 패턴(default export + PascalCase) 수집. **50개 상한** — 넘으면 `components/ui/*` 같은 디자인 시스템 베이스 우선, 나머지 "..." + 안내.

### §4.2 분석 & 인덱스 라인

파일 단위 `Read` → 이름·경로·핵심 props(1~3개)·variant(`variant`/`size`/`color` union)·의존 hook(`use*`) 추출. 형식 — 이름 · 경로 · 핵심 props · variant 한 줄씩:

```
- `Button` · `components/ui/Button.tsx` · `variant: primary|secondary|ghost`, `size: sm|md|lg` · 기본 액션 버튼
- `UserAvatar` · `components/UserAvatar.tsx` · `size: sm|md`, `useAuth()` 의존 · 로그인한 사용자 표시
```

### §4.3 외부 데이터 의존 컴포넌트

외부 데이터 hook(`useAuth`/`useQuery`/`useSession`/`useSWR`/`fetch`)에 의존하면 *디자이너 더미 환경에서 깨질 위험* → §외부 데이터 의존 컴포넌트 별도 섹션에 ⚠️ + mock 안내:

```markdown
## 외부 데이터 의존 컴포넌트 (더미 환경 주의)
- `UserAvatar` — `useAuth()` 의존. 미리보기 하려면 `mock/auth.ts`에 가짜 사용자 박아두는 게 안전.
```

A 분기(§3-D 적용)면 이 섹션의 컴포넌트들이 *§3-D §6 차단 레이어가 흡수 + §7 분기 변환 후보* — 디자이너 첫 작업 시 자연 권유.

## §4.5 페이지 단위 스캔

`§1.3`에서 수집한 `routePaths`를 *디자이너 친화 인덱스*로 → `CLAUDE.project.md` §pages 슬롯.

### §4.5.1 페이지 파일 분석

`routePaths` 각 항목 `Read` → 추출:

| 추출 항목 | 추출 방법 |
|---|---|
| 페이지 이름 | 파일 경로에서 추론 — `app/dashboard/page.tsx` → "대시보드" |
| 라우트 경로 | 프레임워크 컨벤션 역산 — Next App: `app/[lang]/cafe/page.tsx` → `/[lang]/cafe` |
| 역할 1줄 | 페이지 본문에서 추론 — 제목·헤더·주요 컴포넌트로 한국어 1줄 |
| 외부 데이터 의존 | §4.3 컴포넌트 사용 여부 + 직접 fetch 호출 여부 |

**50개 상한** 동일. 동적 라우트(`[id]`·`[...slug]`)는 그대로 + "동적 경로" 표기.

### §4.5.2 인덱스 라인 형식

```
- `대시보드` · `app/dashboard/page.tsx` · `/dashboard` · 로그인 후 첫 화면, 카드 3개
- `프로필` · `app/[lang]/profile/page.tsx` · `/[lang]/profile` (동적) · 사용자 설정 · `useAuth()` 의존
```

페이지 단위는 *디자이너 미리보기·작업 진입점* — `preview`가 dev 서버 띄울 때 이 인덱스로 *어디부터 볼까* 권유.

## 인덱스 후속 회전 = design-system-guard 책임

이 인덱스(컴포넌트·페이지)의 *후속 갱신·회전*은 `design-system-guard` §3(컴포넌트)·§3.1(페이지)로 위임 — 신규/변경 감지 시 자동 갱신, 슬롯 분량이 *디자이너가 한눈에 훑을 만함*을 넘으면 가장 오래된 항목을 `.claude/slot-archive/<슬롯>.md`로 회전(자동 로드 X). 이 Skill은 *초기 일괄 생성*까지만 책임, 자세한 회전 정책 정본: `plugin/SCHEMA.md` §2.3.
