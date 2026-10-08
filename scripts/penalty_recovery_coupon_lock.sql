-- 거절 제재 자동 회복(관리자·신고 제재 하한 유지) + 쿠폰함(user_coupons) 잠금.
--
-- 1) 거절 제재: 단계를 최근 30일 거절 수로 다시 계산해 오래된 거절이 빠지면 내려가게 한다.
--    단, 관리자·신고 처리로 준 단계(penalty_floor) 아래로는 내려가지 않는다.
--    - penalty_floor 는 관리자·심사자가 앱에서 penalty_level 을 바꿀 때 트리거가 같은 값으로 맞춘다
--      (submitResolve 제재 → 하한 1~3, clearPenalty → 하한 0). 앱 코드는 바꾸지 않아도 된다.
--    - 3단계 정지는 '새로 3단계에 들어설 때' 또는 '방금 거절했을 때(p_after_reject)'만 건다.
--      화면을 열 때·매일 돌 때마다 정지가 연장되면 안 되기 때문이다.
--    - 매일 호스트 crontab 이 refresh_all_provider_penalties() 를 부른다(pg_cron 은 이 DB 에 없다).
-- 2) 쿠폰함: 앱 경로 전수 조사(index.html·admin.html, 2026-10-08)
--    - 쿠폰 받기 claimCoupon: INSERT {customer_id, coupon_id}         → 사용 가능한(활성·기한 내) 쿠폰만, 미사용 상태로만
--    - 결제창 사용 처리: UPDATE {is_used:true, used_at} (is_used=false 행) → false→true 만 허용
--    - 관리자 쿠폰 발급(user_coupons 직접 발급)은 없다. 관리자는 coupons 표만 만든다.
--    - 사용 처리는 이제 예약에 쿠폰이 붙는 순간 서버가 한다(토스 결제 경로는 원래 사용 처리를 안 했다).
--    - 예약 취소 시 쿠폰 복원: 기존 코드에 그런 규칙이 없다 → 만들지 않는다.
--    - 삭제는 막는다(쓴 쿠폰을 지우고 다시 받는 재사용 방지). 회원 탈퇴 CASCADE 는 소유자 권한이라 영향 없다.

begin;

-- ── 1) 거절 제재 ──
alter table public.providers add column if not exists penalty_floor integer not null default 0;

create or replace function public.keep_penalty_floor()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
  -- 앱에서 관리자·심사자가 단계를 직접 바꾸면 그 값이 하한이 된다(제재 해제 0 포함)
  if current_user = 'authenticated' and public.is_reviewer()
     and new.penalty_level is distinct from old.penalty_level
     and new.penalty_floor is not distinct from old.penalty_floor then
    new.penalty_floor := coalesce(new.penalty_level, 0);
  end if;
  return new;
end $$;

drop trigger if exists trg_provider_penalty_floor on public.providers;
create trigger trg_provider_penalty_floor
  before update on public.providers
  for each row execute function public.keep_penalty_floor();

-- 권한 검사 없는 내부 계산. 앱에서는 부를 수 없다
create or replace function public.apply_provider_penalty(p_provider uuid, p_after_reject boolean)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  n      integer;
  auto   integer;
  cur    integer;
  floor_ integer;
  lv     integer;
  susp   boolean;
begin
  select coalesce(penalty_level, 0), coalesce(penalty_floor, 0) into cur, floor_ from providers where id = p_provider;
  if not found then return null; end if;
  select count(*) into n from bookings
   where provider_id = p_provider and rejected_at >= now() - interval '30 days';
  -- 앱의 PENALTY_RULES 와 같다: 5회 경고 · 8회 노출저하 · 12회 3일 정지
  auto := case when n >= 12 then 3 when n >= 8 then 2 when n >= 5 then 1 else 0 end;
  lv   := greatest(auto, floor_);
  susp := auto = 3 and (p_after_reject or cur < 3);
  update providers
     set reject_count    = n,
         penalty_level   = lv,
         suspended_until = case when susp then now() + interval '3 days' else suspended_until end,
         is_active       = case when susp then false else is_active end
   where id = p_provider;
  return jsonb_build_object('count', n, 'level', lv);
end $$;
revoke all on function public.apply_provider_penalty(uuid, boolean) from public, anon, authenticated;

drop function if exists public.refresh_provider_penalty(uuid);
create or replace function public.refresh_provider_penalty(p_provider uuid, p_after_reject boolean default false)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  if not public.owns_provider(p_provider) and not public.is_admin() then
    raise exception '권한이 없습니다.' using errcode = '42501';
  end if;
  return public.apply_provider_penalty(p_provider, p_after_reject);
end $$;
revoke all on function public.refresh_provider_penalty(uuid, boolean) from public, anon;
grant execute on function public.refresh_provider_penalty(uuid, boolean) to authenticated;

-- 매일 crontab 이 부른다. 제재·거절 기록이 있는 제공자만 다시 센다
create or replace function public.refresh_all_provider_penalties()
returns integer
language plpgsql
security definer
set search_path to 'public'
as $$
declare r record; k integer := 0;
begin
  for r in select id from providers where coalesce(penalty_level, 0) > 0 or coalesce(reject_count, 0) > 0 loop
    perform public.apply_provider_penalty(r.id, false);
    k := k + 1;
  end loop;
  return k;
end $$;
revoke all on function public.refresh_all_provider_penalties() from public, anon, authenticated;

-- 이미 걸려 있는 단계는 누가 줬는지 알 수 없으므로 하한으로 둔다(갑자기 풀리지 않게). 해제는 관리자 clearPenalty
update public.providers set penalty_floor = penalty_level where coalesce(penalty_level, 0) > 0 and penalty_floor = 0;

-- ── 2) 쿠폰함 ──
create or replace function public.guard_user_coupon_write()
returns trigger
language plpgsql
set search_path to 'public'
as $$
declare
  ch text[];
begin
  if current_user not in ('authenticated', 'anon') or public.is_admin() then
    return coalesce(new, old);
  end if;
  if tg_op = 'DELETE' then
    raise exception '쿠폰함의 쿠폰은 지울 수 없습니다.' using errcode = '42501';
  end if;
  if tg_op = 'INSERT' then
    if coalesce(new.is_used, false) or new.used_at is not null
       or not exists (select 1 from coupons c
                       where c.id = new.coupon_id and c.is_active
                         and (c.valid_until is null or c.valid_until >= (now() at time zone 'Asia/Ho_Chi_Minh')::date)) then
      raise exception '받을 수 없는 쿠폰입니다.' using errcode = '42501';
    end if;
    new.claimed_at := now();
    return new;
  end if;
  ch := public.changed_columns(to_jsonb(old), to_jsonb(new));
  if cardinality(ch) = 0 then
    return new;
  end if;
  if not ch <@ array['is_used', 'used_at'] or old.is_used or not new.is_used then
    raise exception '쿠폰은 사용 처리만 할 수 있습니다.' using errcode = '42501';
  end if;
  new.used_at := now();
  return new;
end $$;

drop trigger if exists trg_user_coupon_guard on public.user_coupons;
create trigger trg_user_coupon_guard
  before insert or update or delete on public.user_coupons
  for each row execute function public.guard_user_coupon_write();

-- 예약에 쿠폰이 붙는 순간 서버가 사용 처리한다(앱의 사용 처리 호출은 이후 0행으로 그냥 지나간다)
create or replace function public.mark_booking_coupon_used()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if new.coupon_id is not null and new.coupon_id is distinct from old.coupon_id then
    update user_coupons set is_used = true, used_at = now()
     where customer_id = new.customer_id and coupon_id = new.coupon_id and not is_used;
  end if;
  return null;
end $$;

drop trigger if exists trg_booking_coupon_used on public.bookings;
create trigger trg_booking_coupon_used
  after update of coupon_id on public.bookings
  for each row execute function public.mark_booking_coupon_used();

commit;
