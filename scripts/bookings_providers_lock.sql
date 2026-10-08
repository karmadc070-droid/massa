-- 예약·제공자 행 권한 잠금: 손님·마사지사는 정해진 칸만 바꾸고 금액·결제·노쇼·인증·등급·제재는 서버와 관리자만 바꾼다.
--
-- 왜: bookings_customer_update / bookings_admin_update(담당 마사지사 포함) / providers_owner_update 가
--     컬럼 제한 없이 행 전체 수정을 허용했다. 손님은 노쇼·취소 기록을 지워 제재를 풀거나 미결제를 결제로,
--     금액·할인액을 아무 값으로 바꿀 수 있었고, 마사지사는 인증·수수료 등급·제재·심사 상태·평점을 스스로 바꿀 수 있었다.
--     예약 제한(booking_blocked_until)은 앱에서만 보고 서버는 보지 않았다.
--
-- 방식: 컬럼 GRANT 가 아니라 BEFORE 트리거. 관리자도 같은 authenticated 역할이라 컬럼 GRANT 로는
--       관리자와 손님을 가를 수 없고, '값이 실제로 바뀐 칸'만 보면 지금 설치된 앱이 같은 값을 다시 보내는
--       요청(현장 결제 확정의 is_paid:false·같은 금액 등)도 그대로 통과한다.
--       service_role(엣지 함수)·보안정의자 함수(postgres)·관리자·심사자는 막지 않는다.
--
-- 앱이 실제로 쓰는 경로 (index.html·admin.html 전수 조사, 2026-10-08)
--   bookings  손님   INSERT 예약(status confirmed, 금액은 서버가 덮어씀)          → 허용(+예약 제한·결제값 검사)
--                    취소 status/cancelled_at/cancel_reason/cancelled_by           → 허용(취소 시각·주체는 서버가 정함)
--                    결제창 payment_method/coupon_id/discount_vnd                  → 허용(쿠폰 검사, 할인액은 서버 계산)
--                    결제창 is_paid:true / amount_vnd 변경(가짜 QR·이체·카드)       → 거부 (앱은 이번에 보내지 않게 고침)
--             마사지사 수락·완료·노쇼·거절 status/…_at/reason/cancelled_by        → 허용(기록 시각은 비어 있을 때만, 서버 시각)
--             관리자   adminSetBooking 등                                         → 그대로
--   providers 신청자 INSERT 신청(pending, 인증·평점·제재 없음)                     → 허용(그 밖의 값이면 거부)
--             마사지사 프로필·사진·영업시간·출근(is_active)·위치·반려 재제출       → 허용
--                    거절 누적 reject_count/penalty_level/suspended_until          → RPC refresh_provider_penalty 로 이전
--             관리자·심사자 승인·인증·등급·제재 해제                               → 그대로
--   엣지 함수(toss-payment)는 service_role 이라 영향 없다.

begin;

-- 두 행 사이에 값이 바뀐 컬럼 이름
create or replace function public.changed_columns(o jsonb, n jsonb)
returns text[]
language sql
immutable
as $$
  select coalesce(array_agg(k.key order by k.key), '{}')
    from jsonb_each(n) k
   where k.value is distinct from (o -> k.key)
$$;
revoke all on function public.changed_columns(jsonb, jsonb) from public, anon;
grant execute on function public.changed_columns(jsonb, jsonb) to authenticated;

-- ── bookings ──
-- 보안정의자가 아니다: current_user 로 '앱 사용자 요청인지'를 가려야 하기 때문이다.
create or replace function public.guard_booking_write()
returns trigger
language plpgsql
set search_path to 'public'
as $$
declare
  uid      uuid := auth.uid();
  ch       text[];
  blocked  timestamptz;
  cp       record;
  ts       text;
begin
  if current_user not in ('authenticated', 'anon') or public.is_admin() then
    return new;
  end if;

  if tg_op = 'INSERT' then
    select booking_blocked_until into blocked from profiles where id = new.customer_id;
    if blocked > now() then
      raise exception '최근 임박 취소·노쇼가 누적되어 % (하노이 시간)까지 새 예약이 제한됩니다.',
        to_char(blocked at time zone 'Asia/Ho_Chi_Minh', 'YYYY-MM-DD HH24:MI')
        using errcode = '42501', hint = 'booking_blocked';
    end if;
    if coalesce(new.is_paid, false) or new.paid_at is not null or new.paid_krw is not null or new.payment_tx is not null
       or new.no_show_at is not null or new.cancelled_at is not null or new.completed_at is not null
       or new.accepted_at is not null or new.rejected_at is not null
       or new.coupon_id is not null or coalesce(new.discount_vnd, 0) <> 0
       or new.status not in ('requested', 'confirmed') or new.service_id is null then
      raise exception '예약을 만들 수 없는 값이 들어 있습니다.' using errcode = '42501';
    end if;
    new.fee_rate := null;  -- 수수료율은 trg_freeze_fee_rate 가 서버 값으로 채운다
    return new;
  end if;

  ch := public.changed_columns(to_jsonb(old), to_jsonb(new));
  if cardinality(ch) = 0 then
    return new;
  end if;

  -- 담당 마사지사: 상태와 그 기록만
  if exists (select 1 from providers pr
              where pr.id = old.provider_id and (pr.profile_id = uid or pr.owner_id = uid)) then
    if not ch <@ array['status', 'accepted_at', 'completed_at', 'rejected_at', 'reject_reason',
                       'cancelled_at', 'cancel_reason', 'cancelled_by', 'no_show_at'] then
      raise exception '마사지사는 예약 상태만 바꿀 수 있습니다: %', array_to_string(ch, ', ') using errcode = '42501';
    end if;
    if old.status in ('cancelled', 'completed', 'no_show') then
      raise exception '이미 끝난 예약은 바꿀 수 없습니다.' using errcode = '42501';
    end if;
    -- 기록 시각은 비어 있을 때 한 번만 찍고, 값은 서버 시각으로 한다(지우기·되돌리기 금지)
    foreach ts in array array['accepted_at', 'completed_at', 'rejected_at', 'cancelled_at', 'no_show_at'] loop
      if ts = any(ch) and ((to_jsonb(old) ->> ts) is not null or (to_jsonb(new) ->> ts) is null) then
        raise exception '기록된 시각은 지우거나 바꿀 수 없습니다: %', ts using errcode = '42501';
      end if;
    end loop;
    if 'accepted_at'  = any(ch) then new.accepted_at  := now(); end if;
    if 'completed_at' = any(ch) then new.completed_at := now(); end if;
    if 'rejected_at'  = any(ch) then new.rejected_at  := now(); end if;
    if 'cancelled_at' = any(ch) then new.cancelled_at := now(); end if;
    if 'no_show_at'   = any(ch) then new.no_show_at   := now(); end if;
    return new;
  end if;

  -- 손님: 취소와 결제 수단·쿠폰 선택만
  if old.customer_id = uid then
    if not ch <@ array['status', 'cancelled_at', 'cancel_reason', 'cancelled_by',
                       'payment_method', 'coupon_id', 'discount_vnd'] then
      raise exception '손님은 예약 취소와 결제 수단·쿠폰 선택만 할 수 있습니다: %', array_to_string(ch, ', ')
        using errcode = '42501';
    end if;
    if ch && array['status', 'cancelled_at', 'cancel_reason', 'cancelled_by'] then
      if new.status <> 'cancelled' or old.status not in ('requested', 'confirmed') then
        raise exception '대기·확정 상태의 예약을 취소하는 것만 할 수 있습니다.' using errcode = '42501';
      end if;
      new.cancelled_at := now();      -- 취소 시각을 앞당겨 '임박 취소'를 피하지 못하게 한다
      new.cancelled_by := 'customer';
    end if;
    if ch && array['payment_method', 'coupon_id', 'discount_vnd'] then
      if old.is_paid or old.status = 'cancelled' then
        raise exception '이미 결제했거나 취소된 예약입니다.' using errcode = '42501';
      end if;
    end if;
    if ch && array['coupon_id', 'discount_vnd'] then
      if old.coupon_id is not null or new.coupon_id is null then
        raise exception '쿠폰은 한 번만 적용할 수 있습니다.' using errcode = '42501';
      end if;
      select c.discount_type, c.discount_value into cp
        from coupons c
        join user_coupons u on u.coupon_id = c.id and u.customer_id = uid and not u.is_used
       where c.id = new.coupon_id and c.is_active
         and (c.valid_until is null or c.valid_until >= (now() at time zone 'Asia/Ho_Chi_Minh')::date)
         and coalesce(c.min_amount_vnd, 0) <= old.amount_vnd
       limit 1;
      if not found then
        raise exception '쓸 수 없는 쿠폰입니다.' using errcode = '42501';
      end if;
      -- 앱의 discountOf 와 같은 계산. 보낸 할인액은 믿지 않는다
      new.discount_vnd := least(old.amount_vnd,
        case when cp.discount_type = 'percent' then round(old.amount_vnd * cp.discount_value / 100.0)
             else cp.discount_value end);
    end if;
    return new;
  end if;

  raise exception '이 예약을 바꿀 권한이 없습니다.' using errcode = '42501';
end $$;

drop trigger if exists trg_booking_guard on public.bookings;
-- 이름이 trg_freeze_* 보다 앞이라 먼저 돈다(같은 시점 트리거는 이름순)
create trigger trg_booking_guard
  before insert or update on public.bookings
  for each row execute function public.guard_booking_write();

-- ── providers ──
create or replace function public.guard_provider_write()
returns trigger
language plpgsql
set search_path to 'public'
as $$
declare
  uid uuid := auth.uid();
  ch  text[];
begin
  if current_user not in ('authenticated', 'anon') or public.is_reviewer() then  -- is_reviewer: 관리자·심사자
    return new;
  end if;

  if tg_op = 'INSERT' then
    -- 신청은 '심사 대기, 아무 표시 없음' 으로만. fee_tier 는 컬럼 기본값(vip) 그대로여야 한다
    if new.application_status is distinct from 'pending'
       or coalesce(new.is_verified, false) or coalesce(new.credential_verified, false) or coalesce(new.hygiene_certified, false)
       or new.credential_checked_at is not null or new.hygiene_checked_at is not null
       or coalesce(new.rating, 0) <> 0 or coalesce(new.review_count, 0) <> 0
       or coalesce(new.penalty_level, 0) <> 0 or coalesce(new.reject_count, 0) <> 0 or new.suspended_until is not null
       or coalesce(new.sort_priority, 0) <> 0 or new.deposit_code is not null
       or new.reviewed_at is not null or new.reviewed_by is not null
       or new.fee_tier is distinct from 'vip' or new.fee_tier_at is not null or new.fee_tier_by is not null
       or (new.profile_id is not null and new.profile_id <> uid)
       or (new.owner_id is not null and new.owner_id <> uid) then
      raise exception '제공자 신청은 심사 대기 상태로만 만들 수 있습니다.' using errcode = '42501';
    end if;
    return new;
  end if;

  ch := public.changed_columns(to_jsonb(old), to_jsonb(new));
  if cardinality(ch) = 0 then
    return new;
  end if;
  if not ch <@ array['display_name', 'photo_url', 'photo_urls', 'bio', 'service_area', 'phone', 'business_hours',
                     'is_active', 'lat', 'lng', 'last_lat', 'last_lng', 'last_seen_at',
                     'application_status', 'reject_reason'] then
    raise exception '이 항목은 운영팀만 바꿀 수 있습니다: %', array_to_string(ch, ', ') using errcode = '42501';
  end if;
  if ch && array['application_status', 'reject_reason']
     and not (old.application_status = 'rejected' and new.application_status = 'pending' and new.reject_reason is null) then
    raise exception '반려된 신청을 다시 제출하는 것만 할 수 있습니다.' using errcode = '42501';
  end if;
  if 'is_active' = any(ch) and new.is_active and old.suspended_until > now() then
    raise exception '예약 접수 정지 기간(%까지)에는 다시 켤 수 없습니다.',
      to_char(old.suspended_until at time zone 'Asia/Ho_Chi_Minh', 'YYYY-MM-DD HH24:MI') using errcode = '42501';
  end if;
  return new;
end $$;

drop trigger if exists trg_provider_guard on public.providers;
create trigger trg_provider_guard
  before insert or update on public.providers
  for each row execute function public.guard_provider_write();

-- 거절 누적 제재는 서버가 예약 기록으로 센다. 규칙은 앱의 PENALTY_RULES 와 같다
-- (최근 30일 거절 5회 경고·8회 노출저하·12회 3일 정지). 단계는 올리기만 한다 —
-- 내리는 것은 관리자(clearPenalty)만. 그래야 신고로 받은 제재를 이 함수로 지우지 못한다.
create or replace function public.refresh_provider_penalty(p_provider uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  n  integer;
  lv integer;
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  if not public.owns_provider(p_provider) and not public.is_admin() then
    raise exception '권한이 없습니다.' using errcode = '42501';
  end if;
  select count(*) into n from bookings
   where provider_id = p_provider and rejected_at >= now() - interval '30 days';
  lv := case when n >= 12 then 3 when n >= 8 then 2 when n >= 5 then 1 else 0 end;
  update providers
     set reject_count    = n,
         penalty_level   = greatest(coalesce(penalty_level, 0), lv),
         suspended_until = case when lv = 3 then now() + interval '3 days' else suspended_until end,
         is_active       = case when lv = 3 then false else is_active end
   where id = p_provider;
  return jsonb_build_object('count', n, 'level', lv);
end $$;

revoke all on function public.refresh_provider_penalty(uuid) from public, anon;
grant execute on function public.refresh_provider_penalty(uuid) to authenticated;

commit;
