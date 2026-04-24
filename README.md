# 리얼워크 팀효과성 진단 — 액션플랜 참고자료 App

팀장이 팀효과성 진단 결과를 보고, 16개 세부주제별로 12개의 액션플랜 예시 중에서
**공감되는 3개를 고르는** 워크샵용 모바일 웹앱입니다.

- 4개 대주제 × 16개 세부주제 × **12개 액션플랜 = 총 192개 카드**
- 각 카드: `액션플랜` (시간/빈도가 포함된 구체 행동) + `기대효과` + `태그`
- 태그: `팀장` · `팀 전체` · `타팀과 함께` 세 가지로 한눈에 분류
- 진단 보고서의 **실제 설문 문구**를 각 세부주제 상단에 표시
- 선택 → 이미지 저장 (`html2canvas`) → 관리자 통계
- **단일 HTML 파일** (빌드 없이 어디든 배포 가능)
- 저장소는 **Supabase** 또는 **localStorage** 자동 fallback

---

## 📁 파일 구성

| 파일 | 설명 |
|---|---|
| `index.html` | 전체 앱 (참여자 + 관리자 + 통계). 이 파일 하나만 있으면 동작 |
| `action-plans.json` | 192개 카드 원본 데이터 (참고/수정용) |
| `supabase-schema.sql` | Supabase DB 테이블·정책·뷰 정의 |
| `README.md` | 이 문서 |

---

## 🧭 앱의 화면 흐름

### 홈 화면
- 상단: **워크숍명 + 날짜** (관리자가 등록한 것)
- “팀효과성 요소를 1가지 선택하세요.”
- 2단 레이아웃:
  - 왼쪽 (**Team Forming**): 팀 목표 · 팀 구조
  - 오른쪽 (**Team Performing**): 팀 동기 · 팀 행동
- 우상단: QR 아이콘 → 현재 페이지의 QR 코드 팝업

### 세부주제 화면
- 헤더: `팀효과성 요소 목록으로` ← 뒤로가기
- 진단 설문 원문(예: “우리 팀에게 주어진 목표는 명확하다.”)을 인용구로 강조
- 12장 카드 (액션플랜/기대효과/태그) 나열
- 공감되는 **3장 선택** → 완료 버튼

### 결과 화면
- 선택한 3장만 확대 표시
- `이미지로 저장` → 1080px 정사각 PNG 다운로드

### 관리자 페이지 (`#/admin`, 비밀번호 기본값 `realwork2026`)
- **워크숍**: 고객사명 + 날짜 등록 → 전용 URL·QR 코드 생성·다운로드
- **카드 편집**: 액션플랜/기대효과/태그 편집
- **일괄 업로드**: Excel 템플릿 다운로드 → 수정 → 업로드
- **통계**: 워크숍별·세부주제별 TOP 카드, CSV/Excel 내보내기
- **설정**: 관리자 비밀번호 변경, Supabase 연결 상태 확인, 초기값 복원

---

## 🚀 빠른 시작 (Supabase 없이도 바로 동작)

1. `index.html` 을 브라우저로 열면 끝.
2. 관리자 페이지 → `index.html#/admin` (비밀번호 기본값 `realwork2026`)
3. 이 상태에서도 참여자가 카드를 선택하고 이미지를 저장할 수 있지만,
   통계는 **해당 브라우저 안에서만** 집계됩니다.
   여러 팀장의 결과를 모으려면 아래 Supabase 설정을 권장합니다.

---

## ☁️ 배포 1 — 정적 호스팅 (권장: Vercel · Netlify · Cloudflare Pages)

1. [Vercel](https://vercel.com) 가입 후 “New Project” → GitHub 리포지토리 연결
   또는 Vercel CLI 로 `vercel deploy` 실행
2. **Build Command 불필요.** Output Directory 는 폴더 그대로
3. `index.html`, `action-plans.json` 두 파일만 올리면 끝
4. 배포된 URL 에서 바로 동작. 모바일 최적화 완료

### Netlify Drop 가장 빠른 배포
- [app.netlify.com/drop](https://app.netlify.com/drop) 에 폴더를 드래그&드롭
  하면 수십 초 안에 공개 URL 생성

---

## ☁️ 배포 2 — Supabase 연동 (실제 워크숍 권장)

### 1) Supabase 프로젝트 생성
- [supabase.com](https://supabase.com) 가입 → New project
- Region: `Tokyo(ap-northeast-1)` 또는 `Seoul` 권장 (없으면 Tokyo)

### 2) DB 스키마 생성
- 좌측 메뉴 SQL Editor → New query
- `supabase-schema.sql` 내용을 복사 · 붙여넣기 · Run
- 3개 테이블이 생성됩니다: `action_plans` · `workshops` · `selections`

### 3) API 키 복사
- Project Settings → API
  - **Project URL** → `SUPABASE_URL`
  - **anon public key** → `SUPABASE_ANON_KEY`

### 4) `index.html` 상단 설정 영역 수정
```js
const SUPABASE_URL       = 'https://your-project-ref.supabase.co';
const SUPABASE_ANON_KEY  = 'eyJ...';
const ADMIN_PASSWORD     = 'realwork2026';   // 꼭 바꾸세요!
```
저장 후 재배포하면 자동으로 Supabase 사용 모드로 전환됩니다.

### 5) 192개 카드 업로드 (최초 1회)
- 관리자 페이지 → `카드 편집` 탭 → `Supabase 동기화` 버튼 클릭
- 또는 `일괄 업로드` 탭에서 Excel 템플릿 다운로드 후 수정 · 업로드

---

## 🧑‍🏫 워크숍 운영 가이드

### 1) 관리자 페이지에서 워크숍 등록
- `#/admin` → **워크숍** 탭 → `워크숍 추가`
- **고객사명** (예: `SK바이오팜`) + **워크숍 날짜** (예: `2026-05-01`) 입력
- 자동으로 `workshop_id` (slug) 가 생성됩니다 (예: `skbiopharm-20260501`)

### 2) 워크숍 URL · QR 배포
- 등록된 워크숍 옆 버튼:
  - `URL 복사` — 클립보드에 URL 복사 → 카카오톡/메일로 공유
  - `QR 보기` — 스크린에 QR 코드 표시
  - `QR 저장` — QR 코드를 PNG 로 다운로드 → PPT·포스터에 삽입
- 참여자는 QR 스캔으로 바로 접속 → 홈 화면 상단에 `SK바이오팜 · 2026.05.01` 표시

워크숍 URL 은 다음과 같은 형태입니다:
```
https://your-app.vercel.app/?w=skbiopharm-20260501
```

### 3) 팀장이 하는 흐름
1. 홈 → 4개 팀효과성 요소 중 진단 결과에서 낮게 나온 주제 선택
2. 세부주제 클릭 → 해당 설문 문구 확인 → 12장 카드 보기
3. 태그(`팀장` · `팀 전체` · `타팀과 함께`) 를 참고해 공감되는 3장 선택
4. 선택한 3장을 `선택 완료` → 결과 화면 `이미지로 저장` → 팀 공유

### 4) 운영자가 보는 흐름 (`#/admin`)
- **워크숍**: 추가/삭제, URL·QR 관리
- **카드 편집**: 192장 카드 액션플랜·기대효과·태그 수정
- **일괄 업로드**: Excel 템플릿 다운로드 → 한 번에 편집 → 업로드
- **통계**: TOP 카드 랭킹, 3장 조합 빈도, 워크숍 필터, CSV/Excel 내보내기
- **설정**: 관리자 비밀번호 변경, 초기값 복원, Supabase 연결 상태 확인

---

## 🗄️ 데이터 모델 요약

### `workshops`
| 컬럼 | 설명 |
|---|---|
| `workshop_id` | slug (예: `skbiopharm-20260501`) |
| `company_name` | 고객사명 |
| `workshop_date` | 실시일 |
| `memo` | 메모 (선택) |

### `action_plans`
| 컬럼 | 설명 |
|---|---|
| `card_id` | 예: `goal_clarity_1` |
| `topic_id` / `subtopic_id` | 대주제 / 세부주제 ID |
| `action_plan` | 시간·빈도가 포함된 구체 행동 |
| `expected_effect` | 실행 시 기대효과 |
| `tags` | `{팀장, 팀 전체, 타팀과 함께}` 중 1개 이상 |
| `order_index` | 카드 정렬 순서 |

### `selections`
| 컬럼 | 설명 |
|---|---|
| `workshop_id` / `workshop_name` | 참여자가 접속한 워크숍 |
| `topic_id` / `subtopic_id` | 어떤 주제에서 선택했는지 |
| `card_ids` | 선택한 3장의 card_id 배열 |
| `created_at` | 제출 시각 |

---

## 🔒 보안 체크리스트

- [ ] `index.html` 의 `ADMIN_PASSWORD` 를 기본값에서 변경했는지
- [ ] Supabase **anon key** 만 프론트엔드에 노출 (service key ❌)
- [ ] 실제 워크숍 전에 브라우저에서 전체 플로우 테스트
- [ ] 민감 정보 수집 시 RLS 정책을 "관리자만 read" 로 강화
- [ ] 관리자 쓰기 정책을 제거할 경우, service_role 키를 쓰는 별도 백엔드 필요

---

## 🎨 디자인 원칙

- 팀부스트 카드 4색 (Goal · Structure · Motivation · Behavior) 사용
- 리얼워크 네이비(#191940) · 민트(#00CCAA) 브랜드 컬러
- Pretendard 타이포그래피
- 모바일 Safe-area 고려, 엄지손가락이 닿는 영역에 CTA 배치
- 태그 색상으로 카드 카테고리를 직관적으로 분류
- 이미지 저장은 1080px 정사각 카드 (인스타/슬랙 공유 최적화)

---

## 🛠️ 추가 편집 팁

- **192개 카드를 한 번에 고칠 때**: 관리자 페이지 `일괄 업로드` →
  Excel 템플릿 다운로드 → 엑셀에서 수정 → 다시 업로드
- **초안 JSON 파일**: `action-plans.json` 을 직접 편집해서 배포 시 포함하면
  기본값이 교체됩니다 (DEFAULT_DATA 대신 이 파일을 우선 사용)
- **배포 후 문구만 빠르게 고치고 싶을 때**: Supabase 콘솔에서 `action_plans`
  테이블을 직접 편집해도 반영됩니다 (페이지 새로고침만 하면 됨)
- **카드 태그 변경**: 관리자 `카드 편집` → 태그 Pill 토글로 즉시 변경
- **세부주제 설문 문구 변경**: `action-plans.json` 의 `question` 필드를 수정

---

## ❓FAQ

**Q. 한 사람이 여러 번 제출할 수 있나요?**
A. 네, 같은 워크숍 ID 라도 매번 새 레코드로 저장됩니다.
중복 방지가 필요하면 관리자 페이지에서 제출 후 완료 화면에 머무르도록 안내하거나,
`selections` 테이블에 unique 제약을 추가하세요.

**Q. 데이터 삭제는 어떻게 하나요?**
A. 관리자 페이지 통계 탭에서 워크숍을 선택 후 `이 워크숍 데이터 삭제` 버튼,
또는 Supabase 콘솔에서 직접 삭제.

**Q. 다른 회사에서도 쓸 수 있나요?**
A. `index.html` 과 `action-plans.json` 만 복제하면 별도 앱으로 운영 가능합니다.

**Q. 카드 12개가 너무 많아요/적어요.**
A. `action-plans.json` 에서 각 subtopic 의 `cards` 배열 길이를 조정하면 됩니다.
UI 는 카드 개수에 관계없이 자동 대응합니다.

---

© 2026 리얼워크 (Realwork) — 팀효과성 진단 기반 액션플랜 앱
