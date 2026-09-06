-- 수수료를 마사지사별 3단계로 나눈다. 우대 10% · 가게 소속 15% · 프리랜서 20%.
-- 핵심 원칙: 요율은 예약이 들어오는 순간 그 예약에 굳는다. 등급을 바꿔도 지난 정산은 움직이지 않는다.

-- ── 1. 등급 ──────────────────────────────────────────────────
do $$ begin
  create type public.fee_tier as enum ('vip', 'shop', 'freelancer');
exception when duplicate_object then null; end $$;

alter table public.providers
  add column if not exists fee_tier    public.fee_tier not null default 'freelancer',
  add column if not exists fee_tier_at timestamptz,
  add column if not exists fee_tier_by uuid;

comment on column public.providers.fee_tier is 'vip=10% · shop=15% · freelancer=20%. 요율 값은 app_settings.fee.tiers 에 있다';

-- ── 2. 예약에 요율을 굳힌다 ──────────────────────────────────
alter table public.bookings add column if not exists fee_rate numeric(5,4);
comment on column public.bookings.fee_rate is '예약이 들어온 시점의 수수료율. 나중에 등급이 바뀌어도 이 값은 그대로다';

-- ── 3. 설정 ──────────────────────────────────────────────────
-- rate 는 등급을 못 찾았을 때의 대체값이다. 가장 높은 값을 두어 덜 받는 실수를 막는다.
update public.app_settings set value = jsonb_build_object(
    'due_days', coalesce((value->>'due_days')::int, 3),
    'rate',     0.20,
    'tiers',    jsonb_build_object('vip', 0.10, 'shop', 0.15, 'freelancer', 0.20),
    'promote',  jsonb_build_object('min_done', 20, 'min_rating', 4.7, 'window_days', 30)
  ), updated_at = now()
 where key = 'fee';

-- ── 4. 요율 조회 ─────────────────────────────────────────────
create or replace function public.fee_rate_of(p_provider uuid)
returns numeric
language sql stable security definer set search_path = public as $$
  select coalesce(
    (select (s.value->'tiers'->>pr.fee_tier::text)::numeric
       from public.providers pr, public.app_settings s
      where pr.id = p_provider and s.key = 'fee'),
    (select (value->>'rate')::numeric from public.app_settings where key = 'fee'),
    0.20);
$$;

-- ── 5. 예약이 생길 때 요율을 박아 넣는다 ─────────────────────
create or replace function public.freeze_fee_rate()
returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.fee_rate is null and new.provider_id is not null then
    new.fee_rate := public.fee_rate_of(new.provider_id);
  end if;
  return new;
end $$;

drop trigger if exists trg_freeze_fee_rate on public.bookings;
create trigger trg_freeze_fee_rate
  before insert on public.bookings
  for each row execute function public.freeze_fee_rate();

-- 지금까지의 예약은 전부 10% 로 계산돼 왔다. 사실 그대로 굳힌다.
update public.bookings set fee_rate = 0.10 where fee_rate is null;

-- ── 6. 정산을 예약별 요율로 ──────────────────────────────────
-- 요율이 예약마다 다르므로 합계에 한 번 곱하면 안 된다. 예약별로 반올림해 더한다.
create or replace function public.close_settlement_cycle(
  p_period_type text, p_start date, p_end date)
returns integer
language plpgsql security definer set search_path = public as $$
declare
  v_due int := 3;
  v_cnt int := 0;
begin
  if not public.is_admin() then
    raise exception '관리자만 마감할 수 있습니다.';
  end if;

  select coalesce((value->>'due_days')::int, 3) into v_due
    from public.app_settings where key = 'fee';

  insert into public.settlement_cycle
    (provider_id, period_type, period_start, period_end, booking_count,
     gross_vnd, fee_vnd, net_vnd, status, due_date, closed_at)
  select b.provider_id, p_period_type, p_start, p_end,
         count(*),
         coalesce(sum(b.amount_vnd), 0),
         coalesce(sum(round(b.amount_vnd * coalesce(b.fee_rate, public.fee_rate_of(b.provider_id)))), 0),
         coalesce(sum(b.amount_vnd), 0)
           - coalesce(sum(round(b.amount_vnd * coalesce(b.fee_rate, public.fee_rate_of(b.provider_id)))), 0),
         'closed', p_end + v_due, now()
  from public.bookings b
  where b.is_paid = true
    and b.provider_id is not null
    and (coalesce(b.completed_at, b.created_at))::date between p_start and p_end
  group by b.provider_id
  on conflict (provider_id, period_type, period_start) do update
    set period_end    = excluded.period_end,
        booking_count = excluded.booking_count,
        gross_vnd     = excluded.gross_vnd,
        fee_vnd       = excluded.fee_vnd,
        net_vnd       = excluded.net_vnd,
        due_date      = excluded.due_date,
        status        = case when public.settlement_cycle.status = 'paid' then 'paid' else 'closed' end,
        closed_at     = now();

  get diagnostics v_cnt = row_count;
  return v_cnt;
end $$;

-- ── 7. 운영 화면용: 등급 목록과 10% 후보 ─────────────────────
-- 후보는 알려 주기만 한다. 등급을 올리는 것은 사람이 누른다.
create or replace function public.admin_provider_fees()
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  cfg jsonb; res jsonb; win int; min_done int; min_rating numeric;
begin
  if not exists (select 1 from profiles where id = auth.uid() and role = 'admin') then
    raise exception '관리자만 조회할 수 있습니다.' using errcode = '42501';
  end if;

  select value into cfg from app_settings where key = 'fee';
  win        := coalesce((cfg->'promote'->>'window_days')::int, 30);
  min_done   := coalesce((cfg->'promote'->>'min_done')::int, 20);
  min_rating := coalesce((cfg->'promote'->>'min_rating')::numeric, 4.7);

  select jsonb_build_object(
    'tiers',   cfg->'tiers',
    'promote', cfg->'promote',
    'rows', coalesce(jsonb_agg(t order by t.done_recent desc, t.rating desc nulls last), '[]'::jsonb)
  ) into res
  from (
    select pr.id, pr.display_name as name, pr.photo_url,
           pr.fee_tier::text as tier,
           (cfg->'tiers'->>pr.fee_tier::text)::numeric as rate,
           pr.rating, pr.review_count, pr.base_district as district,
           pr.deposit_code, pr.fee_tier_at,
           (select count(*) from bookings b
             where b.provider_id = pr.id and b.status = 'completed'
               and b.completed_at >= now() - (win || ' days')::interval)::int as done_recent,
           -- 후보 조건: 최근 실적과 평점이 기준을 넘고, 아직 우대 등급이 아닌 사람
           ((select count(*) from bookings b
              where b.provider_id = pr.id and b.status = 'completed'
                and b.completed_at >= now() - (win || ' days')::interval) >= min_done
            and coalesce(pr.rating, 0) >= min_rating
            and pr.fee_tier <> 'vip') as suggest_vip
    from providers pr
    where pr.application_status = 'approved'
  ) t;

  return res;
end $$;

-- 등급 변경. 누가 언제 바꿨는지 남긴다.
create or replace function public.set_fee_tier(p_provider uuid, p_tier text)
returns void
language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from profiles where id = auth.uid() and role = 'admin') then
    raise exception '관리자만 바꿀 수 있습니다.' using errcode = '42501';
  end if;
  if p_tier not in ('vip', 'shop', 'freelancer') then
    raise exception '등급 값이 올바르지 않습니다: %', p_tier;
  end if;
  update providers
     set fee_tier = p_tier::public.fee_tier, fee_tier_at = now(), fee_tier_by = auth.uid()
   where id = p_provider;
end $$;

revoke execute on function public.admin_provider_fees()          from anon;
revoke execute on function public.set_fee_tier(uuid, text)       from anon;
grant  execute on function public.admin_provider_fees()          to authenticated;
grant  execute on function public.set_fee_tier(uuid, text)       to authenticated;
