-- 대시보드 3차: 수수료를 예약별 요율로 실제 합산한다.
-- 등급(10·15·20%)이 섞이면 거래액에 요율 하나를 곱하는 방식은 틀린 값을 낸다.

create or replace function public.admin_dashboard(
  p_bucket text default 'day', p_periods int default 14)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  tz  constant text := 'Asia/Ho_Chi_Minh';
  tr  text;
  n   int;
  t0  timestamp;    -- 이번 기간 첫 버킷 (하노이 현지시각)
  tp  timestamp;    -- 직전 기간 첫 버킷
  f0  timestamptz;
  fp  timestamptz;
  today date;
  fee numeric;
  res jsonb;
begin
  if not exists (select 1 from profiles where id = auth.uid() and role = 'admin') then
    raise exception '관리자만 조회할 수 있습니다.' using errcode = '42501';
  end if;

  tr := case lower(coalesce(p_bucket, 'day'))
          when 'week' then 'week' when 'month' then 'month'
          when 'year' then 'year' else 'day' end;
  n     := greatest(1, least(coalesce(p_periods, 14), 60));
  today := (now() at time zone tz)::date;
  t0    := date_trunc(tr, (now() at time zone tz)) - ((n - 1) || ' ' || tr)::interval;
  tp    := t0 - (n || ' ' || tr)::interval;   -- 같은 길이만큼 더 앞
  f0    := t0 at time zone tz;
  fp    := tp at time zone tz;

  select coalesce((value->>'rate')::numeric, 0.10) into fee from app_settings where key = 'fee';

  with buckets as (
    select generate_series(t0, date_trunc(tr, (now() at time zone tz)), ('1 ' || tr)::interval) as k
  ),
  first_seen as (
    select device_id, min(visit_date) as d0 from app_visit group by device_id
  ),
  vis as (
    select date_trunc(tr, av.visit_date::timestamp) as k,
           count(*)::int                                      as visits,
           count(*) filter (where av.visit_date = fs.d0)::int  as newbies
    from app_visit av join first_seen fs on fs.device_id = av.device_id
    where av.visit_date >= tp::date
    group by 1
  ),
  usr as (
    select date_trunc(tr, u.created_at at time zone tz) as k, count(*)::int as signups
    from auth.users u where u.created_at >= fp group by 1
  ),
  bk as (
    select date_trunc(tr, b.created_at at time zone tz) as k,
           count(*)::int as total,
           count(*) filter (where b.status in
             ('confirmed','on_the_way','in_progress','completed'))::int  as matched,
           count(*) filter (where b.status = 'completed')::int           as done,
           count(*) filter (where b.status = 'requested')::int           as waiting,
           count(*) filter (where b.status = 'cancelled')::int           as cancelled,
           count(*) filter (where b.status = 'no_show')::int             as no_show,
           coalesce(sum(b.amount_vnd) filter (where b.status = 'completed'), 0)::bigint as gmv,
           coalesce(sum(round(b.amount_vnd * coalesce(b.fee_rate, 0.20)))
                      filter (where b.status = 'completed'), 0)::bigint as fee
    from bookings b where b.created_at >= fp group by 1
  ),
  -- 이번 기간과 직전 기간을 같은 방식으로 합산한다
  win as (
    select 'now' as w, bu.k from buckets bu
    union all
    select 'prev', generate_series(tp, t0 - ('1 ' || tr)::interval, ('1 ' || tr)::interval)
  ),
  sums as (
    select w.w,
           sum(coalesce(v.visits,0))::int    as visits,
           sum(coalesce(v.newbies,0))::int   as newbies,
           sum(coalesce(u.signups,0))::int   as signups,
           sum(coalesce(b.total,0))::int     as bookings,
           sum(coalesce(b.matched,0))::int   as matched,
           sum(coalesce(b.done,0))::int      as done,
           sum(coalesce(b.waiting,0))::int   as waiting,
           sum(coalesce(b.cancelled,0))::int as cancelled,
           sum(coalesce(b.no_show,0))::int   as no_show,
           sum(coalesce(b.gmv,0))::bigint    as gmv,
           sum(coalesce(b.fee,0))::bigint    as fee
    from win w
    left join vis v on v.k = w.k
    left join usr u on u.k = w.k
    left join bk  b on b.k = w.k
    group by w.w
  ),
  series as (
    select coalesce(jsonb_agg(jsonb_build_object(
             'k', to_char(bu.k, case tr when 'year'  then 'YYYY'
                                        when 'month' then 'YYYY-MM'
                                        else 'YYYY-MM-DD' end),
             'visits',    coalesce(v.visits,   0),
             'newbies',   coalesce(v.newbies,  0),
             'signups',   coalesce(u.signups,  0),
             'bookings',  coalesce(b.total,    0),
             'matched',   coalesce(b.matched,  0),
             'done',      coalesce(b.done,     0),
             'waiting',   coalesce(b.waiting,  0),
             'cancelled', coalesce(b.cancelled,0),
             'no_show',   coalesce(b.no_show,  0),
             'gmv',       coalesce(b.gmv,      0),
             'fee',       coalesce(b.fee,      0)) order by bu.k), '[]'::jsonb) as j
    from buckets bu
    left join vis v on v.k = bu.k
    left join usr u on u.k = bu.k
    left join bk  b on b.k = bu.k
  ),
  top as (
    select coalesce(jsonb_agg(t), '[]'::jsonb) as j from (
      select pr.display_name as name, pr.photo_url, pr.rating, pr.review_count,
             pr.base_district as district, pr.fee_tier::text as tier,
             count(b.id)::int                                       as bookings,
             count(b.id) filter (where b.status = 'completed')::int  as done,
             coalesce(sum(b.amount_vnd) filter (where b.status = 'completed'), 0)::bigint as gmv,
             coalesce(sum(round(b.amount_vnd * coalesce(b.fee_rate, 0.20)))
                        filter (where b.status = 'completed'), 0)::bigint as fee
      from providers pr
      join bookings b on b.provider_id = pr.id and b.created_at >= f0
      group by pr.id, pr.display_name, pr.photo_url, pr.rating, pr.review_count,
               pr.base_district, pr.fee_tier
      order by bookings desc, gmv desc
      limit 8) t
  )
  select jsonb_build_object(
    'bucket',   tr,
    'periods',  n,
    'from',     to_char(t0, 'YYYY-MM-DD'),
    'prev_from',to_char(tp, 'YYYY-MM-DD'),
    'fee_rate', fee,
    'fee_tiers', (select value->'tiers' from app_settings where key = 'fee'),
    'series',   (select j from series),
    'top',      (select j from top),
    'sum',      (select to_jsonb(s) - 'w' from sums s where s.w = 'now'),
    'prev',     (select to_jsonb(s) - 'w' from sums s where s.w = 'prev'),
    'today', jsonb_build_object(
      'visits',   (select count(*) from app_visit where visit_date = today),
      'signups',  (select count(*) from auth.users
                    where (created_at at time zone tz)::date = today),
      'bookings', (select count(*) from bookings
                    where (created_at at time zone tz)::date = today),
      'waiting',  (select count(*) from bookings where status = 'requested'),
      'done',     (select count(*) from bookings
                    where (completed_at at time zone tz)::date = today),
      'deposit_pending', (select count(*) from provider_deposit where status = 'reported')),
    'now', jsonb_build_object(
      'members',          (select count(*) from auth.users),
      'providers_total',  (select count(*) from providers),
      'providers_active', (select count(*) from providers
                            where is_active and application_status = 'approved'),
      'providers_pending',(select count(*) from providers
                            where application_status = 'pending'),
      'tier_mix',         (select jsonb_object_agg(fee_tier::text, c) from
                            (select fee_tier, count(*) c from providers
                              where application_status = 'approved' group by 1) x))
  ) into res;

  return res;
end $$;

revoke execute on function public.admin_dashboard(text, int) from anon;
grant  execute on function public.admin_dashboard(text, int) to authenticated;
