# `package.json` Scripts 표준 키 — auto-validate 인터페이스

> `new-service`가 셋업 시 *반드시* 박는 표준 키. `auto-validate` Skill이 우선 호출하는 인터페이스 — 누락 시 일반 fallback으로 빠지면 검증 일관성 깨짐.
>
> 표준 키 정의의 단일 진실은 `plugin/SCHEMA.md` §3. 이 references는 *셋업 시 적용*에 필요한 절차·예시.

## 표준 scripts (셋업 후 최종 형태 — Next.js 기준)

```json
{
  "scripts": {
    "dev": "next dev",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "typecheck": "tsc --noEmit"
  }
}
```

## 표준 키별 fallback

| 키 | Next.js | 그 외 | 비고 |
|---|---|---|---|
| `lint` | `next lint` | `eslint .` | flat config 변환 시 명령 동일 |
| `typecheck` | `tsc --noEmit` | `tsc --noEmit` | tsconfig.json 존재 전제 |
| `check` | 박지 않음 | 박지 않음 | 선택 키 — 사용자 후행 박기 |
| `dev` | `next dev` | 프레임워크별 표준 | — |
| `build` | `next build` | 프레임워크별 표준 | — |

## 적용 절차

1. **`Read` `package.json`** — 현재 scripts 확인.
2. **누락 표준 키만 추가** — *이미 있는 키는 건드리지 않음* (사용자 또는 다른 도구가 박은 값 보존).
3. **`tsconfig.json` 사전 확인** — `typecheck` 박기 *전* `tsconfig.json` 존재 확인 필수. 없으면 `npx tsc --init` 먼저.
4. **`Edit`로 정확히 누락 키만 추가** — 전체 재작성 X.

## 충돌 처리

- 사용자가 `lint`를 다른 명령(예: `biome check .`)으로 박아둔 경우 → *건드리지 않음*. `auto-validate`가 사용자 명령을 그대로 호출.
- `typecheck` 키만 다른 이름(예: `type-check`)으로 박힌 경우 → *건드리지 않음*. `auto-validate`가 표준 키 우선 → 발견 X → 일반 fallback(`tsc --noEmit` 직접)으로 빠짐. 이 경우 사용자가 SCHEMA 위반 인지하고 수정해야 함.

## `import-existing` 적용 시 차이

`import-existing`이 기존 프로젝트를 가져올 때는 *충돌하면 묻지 말고 건드리지 않음* (CLAUDE.md §9). 사용자 셋업이 우선.
