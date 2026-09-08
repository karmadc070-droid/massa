-- 마사지사가 코스마다 자기 가격을 정할 수 있게 한다. 기본가(services.price_vnd)는 그대로 둔다.
--
-- 규칙 (사장님 결정)
--   · 기본가 이상만. 상한은 기본가 × 배수 (app_settings.price.max_multiple, 기본 2배)
--   · 관리자가 승인해야 손님에게 보인다
--   · 코스별로 하나씩
--
-- 가격을 provider_services 에 붙이지 않고 별도 표로 뺀다.
-- provider_services 에는 "인증된 사용자면 누구나 INSERT" 정책이 살아 있어서,
-- 거기에 금액 칸을 두면 남의 프로필 가격을 끼워 넣을 수 있다.
-- 새 표는 RLS 를 켜고 정책을 하나도 만들지 않는다 → PostgREST 로는 아무도 못 읽고 못 쓴다.
-- 아래 security definer 함수로만 오간다.

begin;

create table if not exists public.provider_price (
  provider_id   uuid    not null references public.providers(id) on delete cascade,
  service_id    uuid    not null references public.services(id)  on delete cascade,
  price_vnd     integer,          -- 승인돼 지금 적용 중인 가격. null 이면 기본가를 쓴다
  pending_vnd   integer,          -- 승인 대기 중인 가격
  reject_reason text,
  requested_at  timestamptz,
  reviewed_at   timestamptz,
  reviewed_by   uuid,
  primary key (provider_id, service_id)
);
alter table public.provider_price enable row level security;
-- 정책을 만들지 않는다.

insert into public.app_settings (key, value)
values ('price', jsonb_build_object('max_multiple', 2.0))
on conflict (key) do nothing;

commit;

-- ── 상한 배수 ───────────────────────────────────────────────
-- app_settings 는 RLS 가 걸려 있다. 트리거 안에서도 읽혀야 하므로 definer 로 둔다.
create or replace function public.price_max_multiple()
returns numeric language sql stable security definer set search_path = public as $$
  select coalesce((select (value->>'max_multiple')::numeric
                     from public.app_settings where key = 'price'), 2.0);
$$;

-- ── 실제로 청구할 금액 ──────────────────────────────────────
-- 기본가 미만이거나 상한을 넘는 값은 여기서 잘라 낸다.
-- 설정 배수를 나중에 낮춰도 이미 승인된 가격이 상한을 넘긴 채로 청구되지 않는다.
create or replace function public.effective_price(p_provider uuid, p_service uuid)
returns integer language plpgsql stable security definer set search_path = public as $$
declare base integer; own integer;
begin
  select price_vnd into base from public.services where id = p_service;
  if base is null then return null; end if;
  if p_provider is null then return base; end if;

  select price_vnd into own from public.provider_price
   where provider_id = p_provider and service_id = p_service;
  if own is null then return base; end if;

  return least(greatest(own, base), round(base * public.price_max_multiple())::integer);
end $$;

-- ── 예약 금액은 서버가 정한다 ───────────────────────────────
-- 손님 화면이 보낸 amount_vnd 를 믿지 않는다.
-- 예전에 코스를 못 찾으면 850,000₫ 을 임의로 물리던 자리가 여기다. 이제 화면이 무엇을 보내든 덮어쓴다.
create or replace function public.freeze_booking_amount()
returns trigger language plpgsql security definer set search_path = public as $$
declare srv integer;
begin
  if new.service_id is null then return new; end if;   -- 코스 없는 예약은 손대지 않는다
  srv := public.effective_price(new.provider_id, new.service_id);
  if srv is not null then new.amount_vnd := srv; end if;
  return new;
end $$;

drop trigger if exists trg_freeze_booking_amount on public.bookings;
create trigger trg_freeze_booking_amount
  before insert on public.bookings
  for each row execute function public.freeze_booking_amount();

-- ── 파트너: 내 코스와 가격 ──────────────────────────────────
create or replace function public.provider_my_prices(p_provider uuid)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare uid uuid := auth.uid(); mult numeric;
begin
  if uid is null then raise exception '로그인이 필요합니다.'; end if;
  if not exists (select 1 from public.providers p
                  where p.id = p_provider
                    and (p.profile_id = uid or p.owner_id = uid))
     and not public.is_admin() then
    raise exception '본인 프로필만 볼 수 있습니다.';
  end if;

  mult := public.price_max_multiple();
  return jsonb_build_object(
    'max_multiple', mult,
    'rows', coalesce((
      select jsonb_agg(jsonb_build_object(
               'service_id',   s.id,
               'name',         s.name,
               'category',     s.category::text,
               'duration_min', s.duration_min,
               'base_vnd',     s.price_vnd,
               'cap_vnd',      round(s.price_vnd * mult)::integer,
               'price_vnd',    pp.price_vnd,
               'pending_vnd',  pp.pending_vnd,
               'reject_reason',pp.reject_reason)
             order by s.category::text, s.name, s.duration_min)
        from public.provider_services ps
        join public.services s
          on s.id = ps.service_id and s.is_active
        left join public.provider_price pp
          on pp.provider_id = ps.provider_id and pp.service_id = s.id
       where ps.provider_id = p_provider), '[]'::jsonb));
end $$;

-- ── 파트너: 가격 올리기 ─────────────────────────────────────
create or replace function public.provider_set_price(p_provider uuid, p_service uuid, p_price integer)
returns text language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); base integer; cap integer;
begin
  if uid is null then raise exception '로그인이 필요합니다.'; end if;
  if not exists (select 1 from public.providers p
                  where p.id = p_provider
                    and (p.profile_id = uid or p.owner_id = uid))
     and not public.is_admin() then
    raise exception '본인 프로필만 바꿀 수 있습니다.';
  end if;
  if not exists (select 1 from public.provider_services
                  where provider_id = p_provider and service_id = p_service) then
    raise exception '내가 제공하지 않는 코스입니다.';
  end if;

  select price_vnd into base from public.services where id = p_service and is_active;
  if base is null then raise exception '없는 코스입니다.'; end if;

  -- 비우면 기본가로 되돌린다. 내려가는 쪽이라 손님에게 불리하지 않으므로 승인을 받지 않는다.
  if p_price is null then
    delete from public.provider_price where provider_id = p_provider and service_id = p_service;
    return '기본가로 되돌렸습니다.';
  end if;

  cap := round(base * public.price_max_multiple())::integer;
  if p_price < base then
    raise exception '기본가 %₫ 보다 낮게는 정할 수 없습니다.', to_char(base, 'FM999,999,999');
  end if;
  if p_price > cap then
    raise exception '상한 %₫ 을 넘을 수 없습니다.', to_char(cap, 'FM999,999,999');
  end if;

  insert into public.provider_price (provider_id, service_id, pending_vnd, requested_at, reject_reason)
  values (p_provider, p_service, p_price, now(), null)
  on conflict (provider_id, service_id) do update
     set pending_vnd   = excluded.pending_vnd,
         requested_at  = now(),
         reject_reason = null;
  return '승인 요청이 접수되었습니다.';
end $$;

-- ── 관리자: 승인 대기 목록 ──────────────────────────────────
create or replace function public.admin_price_requests()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then raise exception '관리자만 볼 수 있습니다.'; end if;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
             'provider_id',   pp.provider_id,
             'provider_name', p.display_name,
             'service_id',    pp.service_id,
             'service_name',  s.name,
             'duration_min',  s.duration_min,
             'base_vnd',      s.price_vnd,
             'cap_vnd',       round(s.price_vnd * public.price_max_multiple())::integer,
             'current_vnd',   pp.price_vnd,
             'pending_vnd',   pp.pending_vnd,
             'requested_at',  pp.requested_at)
           order by pp.requested_at)
      from public.provider_price pp
      join public.providers p on p.id = pp.provider_id
      join public.services  s on s.id = pp.service_id
     where pp.pending_vnd is not null), '[]'::jsonb);
end $$;

-- ── 관리자: 승인 / 반려 ─────────────────────────────────────
create or replace function public.admin_review_price(
  p_provider uuid, p_service uuid, p_approve boolean, p_reason text default null)
returns text language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid(); want integer; base integer; cap integer;
begin
  if not public.is_admin() then raise exception '관리자만 처리할 수 있습니다.'; end if;

  select pending_vnd into want from public.provider_price
   where provider_id = p_provider and service_id = p_service;
  if want is null then raise exception '대기 중인 요청이 없습니다.'; end if;

  if not p_approve then
    update public.provider_price
       set pending_vnd = null,
           reject_reason = coalesce(nullif(btrim(p_reason), ''), '승인되지 않았습니다.'),
           reviewed_at = now(), reviewed_by = uid
     where provider_id = p_provider and service_id = p_service;
    return '반려했습니다.';
  end if;

  -- 승인할 때도 범위를 다시 본다. 요청 이후에 기본가나 배수가 바뀌었을 수 있다.
  select price_vnd into base from public.services where id = p_service;
  cap := round(base * public.price_max_multiple())::integer;
  if want < base or want > cap then
    raise exception '지금 기준(% ~ %₫)을 벗어나 승인할 수 없습니다. 다시 요청하게 해 주세요.',
      to_char(base, 'FM999,999,999'), to_char(cap, 'FM999,999,999');
  end if;

  update public.provider_price
     set price_vnd = want, pending_vnd = null, reject_reason = null,
         reviewed_at = now(), reviewed_by = uid
   where provider_id = p_provider and service_id = p_service;
  return '승인했습니다.';
end $$;

-- ── 손님 앱이 읽는 공개 가격 ────────────────────────────────
-- { "<마사지사 id>": { "<코스 id>": 650000, ... }, ... }
-- 승인된 것만, 출근 중인 승인 마사지사만 나간다.
create or replace function public.public_provider_prices()
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_object_agg(k, v), '{}'::jsonb) from (
    select pp.provider_id::text as k,
           jsonb_object_agg(pp.service_id::text,
                            public.effective_price(pp.provider_id, pp.service_id)) as v
      from public.provider_price pp
      join public.providers p
        on p.id = pp.provider_id and p.application_status = 'approved'
      join public.services s
        on s.id = pp.service_id and s.is_active
     where pp.price_vnd is not null
     group by pp.provider_id) t;
$$;

-- ── 확인 ─────────────────────────────────────────────────────
select '표' as 항목,
       case when to_regclass('public.provider_price') is not null then '만들어짐' else '★ 없음' end as 상태
union all
select '정책 수 (0 이어야 한다)', count(*)::text from pg_policies
 where schemaname = 'public' and tablename = 'provider_price'
union all
select '금액 트리거',
       case when exists (select 1 from pg_trigger
                          where tgname = 'trg_freeze_booking_amount' and not tgisinternal)
            then '걸림' else '★ 없음' end
union all
select '상한 배수', public.price_max_multiple()::text
union all
select '함수 ' || p.proname, '있음'
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public'
   and p.proname in ('effective_price','provider_my_prices','provider_set_price',
                     'admin_price_requests','admin_review_price','public_provider_prices')
 order by 1;
