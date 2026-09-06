-- 관리자 대시보드용 유입 기록 테이블과 기간별 집계 함수.

-- ── 1) 유입 기록 ────────────────────────────────────────────────
-- IP 나 개인정보는 담지 않는다. 기기별 랜덤 ID + 날짜로 하루 한 줄만 남긴다.
create table if not exists public.app_visit (
  visit_date date        not null,
  device_id  text        not null,
  platform   text,
  lang       text,
  is_member  boolean     not null default false,
  created_at timestamptz not null default now(),
  primary key (visit_date, device_id)
);

-- 정책을 하나도 만들지 않는다. RLS 가 켜져 있고 정책이 없으면 PostgREST 로는
-- 아무도 읽지도 쓰지도 못한다. 쓰기는 track_visit(), 읽기는 admin_dashboard() 만 한다.
alter table public.app_visit enable row level security;

create or replace function public.track_visit(
  p_device text, p_platform text default null, p_lang text default null)
returns void
language sql security definer set search_path = public as $$
  insert into public.app_visit (visit_date, device_id, platform, lang, is_member)
  values ((now() at time zone 'Asia/Ho_Chi_Minh')::date,
          left(p_device, 64), left(p_platform, 24), left(p_lang, 8), auth.uid() is not null)
  on conflict (visit_date, device_id) do nothing;
$$;
grant execute on function public.track_visit(text, text, text) to anon, authenticated;

-- ── 2) 집계 ────────────────────────────────────────────────────
-- 한 번의 호출로 대시보드 한 화면을 다 채운다. 수수료 곱은 화면에서 한다.
create or replace function public.admin_dashboard(
  p_bucket text default 'day', p_periods int default 14)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  tz  constant text := 'Asia/Ho_Chi_Minh';
  tr  text;
  n   int;
  t0  timestamp;    -- 하노이 현지시각 기준 첫 버킷
  f0  timestamptz;  -- 같은 시점의 절대시각 (created_at 비교용)
  fee numeric;
  res jsonb;
begin
  -- is_admin() 을 부르지 않고 직접 본다. 이 함수 하나만 읽어도 권한 조건이 보이게.
  if not exists (select 1 from profiles where id = auth.uid() and role = 'admin') then
    raise exception '관리자만 조회할 수 있습니다.' using errcode = '42501';
  end if;

  tr := case lower(coalesce(p_bucket, 'day'))
          when 'week'  then 'week'
          when 'month' then 'month'
          when 'year'  then 'year'
          else 'day' end;
  n  := greatest(1, least(coalesce(p_periods, 14), 60));
  t0 := date_trunc(tr, (now() at time zone tz)) - ((n - 1) || ' ' || tr)::interval;
  f0 := t0 at time zone tz;

  select coalesce((value->>'rate')::numeric, 0.10) into fee from app_settings where key = 'fee';

  with buckets as (
    select generate_series(t0, date_trunc(tr, (now() at time zone tz)), ('1 ' || tr)::interval) as k
  ),
  -- 기기가 처음 등장한 날 = 신규. 범위 밖 과거까지 봐야 "신규"가 정확하다.
  first_seen as (
    select device_id, min(visit_date) as d0 from app_visit group by device_id
  ),
  vis as (
    select date_trunc(tr, av.visit_date::timestamp) as k,
           count(*)::int                                    as visits,
           count(*) filter (where av.visit_date = fs.d0)::int as newbies
    from app_visit av join first_seen fs on fs.device_id = av.device_id
    where av.visit_date >= t0::date
    group by 1
  ),
  usr as (
    select date_trunc(tr, u.created_at at time zone tz) as k, count(*)::int as signups
    from auth.users u where u.created_at >= f0 group by 1
  ),
  bk as (
    select date_trunc(tr, b.created_at at time zone tz) as k,
           count(*)::int as total,
           count(*) filter (where b.status in
             ('confirmed','on_the_way','in_progress','completed'))::int as matched,
           count(*) filter (where b.status = 'completed')::int          as done,
           count(*) filter (where b.status in ('cancelled','no_show'))::int as lost,
           coalesce(sum(b.amount_vnd) filter (where b.status = 'completed'), 0)::bigint as gmv
    from bookings b where b.created_at >= f0 group by 1
  ),
  series as (
    select coalesce(jsonb_agg(jsonb_build_object(
             'k', to_char(bu.k, case tr when 'year'  then 'YYYY'
                                        when 'month' then 'YYYY-MM'
                                        else 'YYYY-MM-DD' end),
             'visits',   coalesce(v.visits,  0),
             'newbies',  coalesce(v.newbies, 0),
             'signups',  coalesce(u.signups, 0),
             'bookings', coalesce(b.total,   0),
             'matched',  coalesce(b.matched, 0),
             'done',     coalesce(b.done,    0),
             'lost',     coalesce(b.lost,    0),
             'gmv',      coalesce(b.gmv,     0)) order by bu.k), '[]'::jsonb) as j
    from buckets bu
    left join vis v on v.k = bu.k
    left join usr u on u.k = bu.k
    left join bk  b on b.k = bu.k
  ),
  top as (
    select coalesce(jsonb_agg(t), '[]'::jsonb) as j from (
      select pr.display_name as name, pr.rating, pr.review_count,
             count(b.id)::int                                        as bookings,
             count(b.id) filter (where b.status = 'completed')::int   as done,
             coalesce(sum(b.amount_vnd) filter (where b.status = 'completed'), 0)::bigint as gmv
      from providers pr
      join bookings b on b.provider_id = pr.id and b.created_at >= f0
      group by pr.id, pr.display_name, pr.rating, pr.review_count
      order by bookings desc, gmv desc
      limit 10) t
  )
  select jsonb_build_object(
    'bucket',   tr,
    'periods',  n,
    'from',     to_char(t0, 'YYYY-MM-DD'),
    'fee_rate', fee,
    'series',   (select j from series),
    'top',      (select j from top),
    'now', jsonb_build_object(
      'members',          (select count(*) from auth.users),
      'providers_total',  (select count(*) from providers),
      'providers_active', (select count(*) from providers
                            where is_active and application_status = 'approved'),
      'deposit_pending',  (select count(*) from provider_deposit where status = 'reported'))
  ) into res;

  return res;
end $$;

revoke execute on function public.admin_dashboard(text, int) from anon;
grant  execute on function public.admin_dashboard(text, int) to authenticated;
