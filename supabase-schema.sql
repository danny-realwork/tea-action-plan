-- =============================================================================
-- 리얼워크 팀효과성 진단 액션플랜 웹앱 - Supabase 스키마 (v2)
-- =============================================================================
-- 사용법:
--   1) Supabase 프로젝트를 만든 뒤 (https://supabase.com)
--   2) SQL Editor 에 이 파일을 붙여넣고 Run 실행
--   3) index.html 상단의 SUPABASE_URL, SUPABASE_ANON_KEY 값을 교체
--
--   ※ 기존 v1 (160개 카드 / session_code 구조) 에서 업그레이드 하는 경우
--      기존 테이블을 drop 후 이 파일을 새로 실행하는 것을 권장합니다.
--      (또는 아래 MIGRATION 블록을 주석 해제하여 alter 실행)
-- =============================================================================

-- 0. (선택) v1 → v2 마이그레이션
-- v1 에서 업그레이드할 때만 필요. 처음 실행이라면 이 블록은 건너뛰세요.
-- -----------------------------------------------------------------------------
-- alter table public.action_plans rename column title       to action_plan;
-- alter table public.action_plans rename column description to expected_effect;
-- alter table public.action_plans add column if not exists tags text[] not null default '{}';
-- drop view if exists public.v_session_summary;
-- alter table public.selections rename column session_code to workshop_id;
-- alter table public.selections rename column session_name to workshop_name;
-- alter table public.selections drop column if exists team_name;
-- alter table public.selections drop column if exists leader_name;


-- 1. 액션플랜 카드 테이블 (192개 기본 카드 + 관리자 편집본)
-- -----------------------------------------------------------------------------
create table if not exists public.action_plans (
  card_id          text primary key,                        -- 예: "goal_clarity_1"
  topic_id         text not null,                           -- goal | structure | motivation | behavior
  subtopic_id      text not null,                           -- 예: "goal_clarity"
  action_plan      text not null,                           -- 액션플랜 (시간/빈도가 포함된 구체 행동)
  expected_effect  text not null,                           -- 기대효과 (액션이 가져다 주는 긍정적 영향)
  tags             text[] not null default '{}',            -- ["팀장", "팀 전체", "타팀과 함께"] 중 1~다수
  order_index      int  not null default 0,
  updated_at       timestamptz not null default now()
);

create index if not exists idx_action_plans_subtopic
  on public.action_plans (subtopic_id, order_index);

create index if not exists idx_action_plans_tags
  on public.action_plans using gin (tags);


-- 2. 워크숍 테이블 (관리자가 등록하는 고객사별 워크숍)
-- -----------------------------------------------------------------------------
create table if not exists public.workshops (
  workshop_id     text primary key,                         -- 예: "skbiopharm-20260501" (slug)
  company_name    text not null,                            -- 예: "SK바이오팜"
  workshop_date   date not null,                            -- 워크숍 실시일
  memo            text,                                     -- 내부 메모 (선택)
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists idx_workshops_date
  on public.workshops (workshop_date desc);


-- 3. 선택 결과 수집 테이블 (워크샵 참여자가 고른 3장)
-- -----------------------------------------------------------------------------
create table if not exists public.selections (
  id              bigserial primary key,
  workshop_id     text not null,                            -- workshops.workshop_id 참조 (FK 아님: 외부 배포도 허용)
  workshop_name   text,                                     -- 집계 편의를 위한 비정규화 컬럼 (company_name + date)
  topic_id        text not null,
  subtopic_id     text not null,
  card_ids        text[] not null,                          -- 선택된 카드 3장의 id 배열
  created_at      timestamptz not null default now()
);

create index if not exists idx_selections_workshop
  on public.selections (workshop_id, created_at desc);
create index if not exists idx_selections_subtopic
  on public.selections (subtopic_id, created_at desc);


-- 4. Row Level Security
-- -----------------------------------------------------------------------------
alter table public.action_plans enable row level security;
alter table public.workshops    enable row level security;
alter table public.selections   enable row level security;

-- 누구나 카드를 읽을 수 있도록 (참여자 앱에서 필요)
drop policy if exists "action_plans_read_all" on public.action_plans;
create policy "action_plans_read_all"
  on public.action_plans for select using (true);

-- 누구나 워크숍 목록을 읽을 수 있도록 (참여자 페이지에서 워크숍 이름 표시용)
drop policy if exists "workshops_read_all" on public.workshops;
create policy "workshops_read_all"
  on public.workshops for select using (true);

-- 누구나 선택 결과를 제출할 수 있도록
drop policy if exists "selections_insert_all" on public.selections;
create policy "selections_insert_all"
  on public.selections for insert with check (true);

-- 누구나 통계 조회를 위해 선택 결과를 조회할 수 있도록
drop policy if exists "selections_read_all" on public.selections;
create policy "selections_read_all"
  on public.selections for select using (true);

-- 관리자 쓰기 권한 -----------------------------------------------------------
-- 기본값: anon key 로 쓰기 허용. 브라우저 관리자 페이지가 바로 편집 가능.
-- 보안이 중요하다면 아래 3개 정책을 주석 처리하고 service_role 키를 별도
-- 서버에서 사용하는 방식으로 전환하세요.

drop policy if exists "action_plans_write_all" on public.action_plans;
create policy "action_plans_write_all"
  on public.action_plans for all
  using (true) with check (true);

drop policy if exists "workshops_write_all" on public.workshops;
create policy "workshops_write_all"
  on public.workshops for all
  using (true) with check (true);

-- selections 은 삭제 권한이 필요 (관리자가 워크숍 데이터 삭제할 때)
drop policy if exists "selections_delete_all" on public.selections;
create policy "selections_delete_all"
  on public.selections for delete using (true);


-- =============================================================================
-- 유용한 집계 뷰 (선택 사항)
-- =============================================================================

-- TOP 카드 집계 뷰 - 세부주제별로 가장 많이 선택된 카드
create or replace view public.v_card_rank as
select
  s.subtopic_id,
  c as card_id,
  count(*) as pick_count
from public.selections s,
     unnest(s.card_ids) as c
group by s.subtopic_id, c
order by s.subtopic_id, pick_count desc;

-- 워크숍별 참여 수
create or replace view public.v_workshop_summary as
select
  workshop_id,
  workshop_name,
  count(*)                    as total_selections,
  count(distinct subtopic_id) as subtopic_count,
  max(created_at)             as last_submission
from public.selections
group by workshop_id, workshop_name
order by last_submission desc nulls last;

-- 태그별 카드 분포 (관리자 대시보드용)
create or replace view public.v_tag_distribution as
select
  ap.topic_id,
  ap.subtopic_id,
  t as tag,
  count(*) as card_count
from public.action_plans ap,
     unnest(ap.tags) as t
group by ap.topic_id, ap.subtopic_id, t
order by ap.topic_id, ap.subtopic_id, card_count desc;
