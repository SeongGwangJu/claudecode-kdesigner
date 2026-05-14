# 이번 사이클 변경분 스캔 (CHANGED_FILES 산출)

SKILL §2 영역 분리·§3 외부 데이터 의존 컴포넌트 표기에서 *이번 사이클*만 잡기 위한 절차.

## BASE_SHA 읽기

`/kdesigner:프로젝트시작`·`new-service`·`import-existing`·`safe-save`가 박은 *디자이너 모드 진입 시점 SHA*:

```bash
BASE_SHA="$(cat .claude/.kd-session-base 2>/dev/null)"
```

`git cat-file -e $BASE_SHA` 성공 = 정상. 실패·부재 = fallback.

## 정상 분기 — CHANGED_FILES 추출

```bash
git diff $BASE_SHA..HEAD --name-only --diff-filter=AMR
```

이후 §2.1 분류·§2.2 mock import 추출·§3.2 데이터 hook 스캔은 *이 목록 안에서만*.

### mock import (이번 추가분)

```bash
git diff $BASE_SHA..HEAD -- '*.tsx' '*.ts' '*.jsx' '*.js' \
  | grep -E "^\+.*from ['\"].*mock"
```

추가 라인(`+`) — *이번 사이클에 새로 도입한 연결 지점*만 잡힘.

### 데이터 hook (이번 추가분)

```bash
git diff $BASE_SHA..HEAD -- '*.tsx' '*.ts' '*.jsx' '*.js' \
  | grep -E "^\+.*\b(useAuth|useSession|useQuery|useSWR|useMutation|fetch\(|axios)"
```

`CLAUDE.project.md` § 외부 데이터 의존 컴포넌트에 이미 있는 항목은 중복 표기 X.

## Fallback 분기 — BASE_SHA 부재·무효

전체 grep — 기존 동작 유지:

```bash
grep -rn "from ['\"].*mock" components/ app/ src/
grep -rnE "\b(useAuth|useSession|useQuery|useSWR|useMutation|fetch\(|axios)" components/ app/ src/
```

이때 응답에 한계 1줄 — *옛 mock·옛 import까지 끌어와 잘못된 인계*를 줄 위험이 있음을 디자이너에게 알림:

> 이번 사이클 시작 시점이 기록되지 않아 전체 파일 기준으로 인계 정리했어요. 일부가 기존 코드와 섞일 수 있어요.

## 멱등 보장

스캔 자체는 read-only. 회차 파일 생성 *후*에만 §publishing-guard 큐 비움. 회차 파일 작성 실패 시 큐 그대로 두고 다음 회차가 흡수.
