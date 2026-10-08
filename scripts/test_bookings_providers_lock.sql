-- 예약·제공자 권한 잠금 시험: 손님·마사지사가 금액·결제·노쇼·인증·등급·제재를 못 바꾸고, 정상 경로는 그대로 되는지 본다. 전부 트랜잭션 안, 끝에 롤백한다.
-- 예약 INSERT 는 알림 행(→ pg_net 큐)을 만들지만 같은 트랜잭션이라 롤백과 함께 사라져 실제 푸시는 나가지 않는다.
\set ON_ERROR_STOP on
begin;

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000e1', 'lock-cust@test.massa'),
  ('00000000-0000-0000-0000-0000000000e2', 'lock-blocked@test.massa'),
  ('00000000-0000-0000-0000-0000000000e3', 'lock-prov@test.massa'),
  ('00000000-0000-0000-0000-0000000000e4', 'lock-admin@test.massa');
insert into public.profiles (id, full_name, role, booking_blocked_until) values
  ('00000000-0000-0000-0000-0000000000e1', '손님', 'customer', null),
  ('00000000-0000-0000-0000-0000000000e2', '제한손님', 'customer', now() + interval '3 days'),
  ('00000000-0000-0000-0000-0000000000e3', '마사지사', 'customer', null),
  ('00000000-0000-0000-0000-0000000000e4', '관리자', 'admin', null)
on conflict (id) do update set full_name = excluded.full_name, role = excluded.role,
  booking_blocked_until = excluded.booking_blocked_until;

-- 마사지사 행: P(승인, 지난 정지 기록, 노출저하 2) · P2(반려된 신청)
insert into public.providers (id, profile_id, owner_id, display_name, application_status, is_active, penalty_level, suspended_until) values
  ('00000000-0000-0000-0000-0000000000f1', '00000000-0000-0000-0000-0000000000e3', null, '시험P', 'approved', true, 2, now() - interval '1 day'),
  ('00000000-0000-0000-0000-0000000000f2', null, '00000000-0000-0000-0000-0000000000e3', '시험P2', 'rejected', false, 0, null);
update public.providers set reject_reason = '사진 부족' where id = '00000000-0000-0000-0000-0000000000f2';
-- P 의 2단계는 관리자가 준 제재로 둔다(하한 2) — 거절 1건으로 재계산해도 내려가지 않아야 한다
update public.providers set penalty_floor = 2 where id = '00000000-0000-0000-0000-0000000000f1';

insert into public.coupons (id, code, title, discount_type, discount_value, min_amount_vnd, is_active) values
  ('00000000-0000-0000-0000-0000000000c1', 'LOCKTEST', '시험쿠폰', 'percent', 10, 0, true);
insert into public.user_coupons (customer_id, coupon_id) values ('00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000c1');

-- 예약: B1(확정·미결제) B2(취소용) B3(노쇼 기록) B4(마사지사 노쇼 처리용) B5(거절 기록)
insert into public.bookings (id, customer_id, provider_id, service_id, scheduled_at, location_type, status, payment_method, amount_vnd, is_paid, no_show_at, rejected_at) values
  ('00000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000f1', null, now() + interval '3 hours', 'hotel', 'confirmed', 'card_onsite', 500000, false, null, null),
  ('00000000-0000-0000-0000-0000000000b2', '00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000f1', null, now() + interval '3 hours', 'hotel', 'confirmed', 'card_onsite', 500000, false, null, null),
  ('00000000-0000-0000-0000-0000000000b3', '00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000f1', null, now() - interval '1 day', 'hotel', 'cancelled', 'card_onsite', 500000, false, now() - interval '1 day', null),
  ('00000000-0000-0000-0000-0000000000b4', '00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000f1', null, now() - interval '10 minutes', 'hotel', 'confirmed', 'card_onsite', 500000, false, null, null),
  ('00000000-0000-0000-0000-0000000000b5', '00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000f1', null, now() + interval '1 day', 'hotel', 'cancelled', 'card_onsite', 500000, false, null, now() - interval '1 hour');

set local role authenticated;

-- ── 손님 ──
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-0000000000e1", "role": "authenticated"}', true);
do $$
declare r record;
begin
  begin
    update public.bookings set is_paid = true where id = '00000000-0000-0000-0000-0000000000b1';
    raise exception 'FAIL: 손님이 결제 완료로 바꿈';
  exception when insufficient_privilege then null; end;
  begin
    update public.bookings set amount_vnd = 1 where id = '00000000-0000-0000-0000-0000000000b1';
    raise exception 'FAIL: 손님이 금액을 바꿈';
  exception when insufficient_privilege then null; end;
  begin
    update public.bookings set discount_vnd = 400000 where id = '00000000-0000-0000-0000-0000000000b1';
    raise exception 'FAIL: 손님이 쿠폰 없이 할인액을 넣음';
  exception when insufficient_privilege then null; end;
  begin
    update public.bookings set no_show_at = null where id = '00000000-0000-0000-0000-0000000000b3';
    raise exception 'FAIL: 손님이 노쇼 기록을 지움';
  exception when insufficient_privilege then null; end;
  begin
    update public.bookings set cancelled_at = null, status = 'confirmed' where id = '00000000-0000-0000-0000-0000000000b3';
    raise exception 'FAIL: 손님이 취소 기록을 지움';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.bookings (customer_id, provider_id, service_id, scheduled_at, location_type, status, payment_method, amount_vnd, is_paid)
    values ('00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000f1', (select id from public.services limit 1),
            now() + interval '1 day', 'hotel', 'confirmed', 'card_onsite', 500000, true);
    raise exception 'FAIL: 손님이 결제 완료 상태로 예약을 만듦';
  exception when insufficient_privilege then null; end;

  -- 정상: 현장 결제 확정(구 앱이 보내는 모양 그대로 — is_paid false, 같은 금액)
  update public.bookings set payment_method = 'card_onsite', is_paid = false, amount_vnd = 500000
   where id = '00000000-0000-0000-0000-0000000000b1';
  if not found then raise exception 'FAIL: 현장 결제 확정 안 됨'; end if;
  -- 정상: 쿠폰 적용 — 할인액은 서버가 계산한다(보낸 999999 는 무시)
  update public.bookings set coupon_id = '00000000-0000-0000-0000-0000000000c1', discount_vnd = 999999
   where id = '00000000-0000-0000-0000-0000000000b1';
  select discount_vnd, amount_vnd into r from public.bookings where id = '00000000-0000-0000-0000-0000000000b1';
  if r.discount_vnd <> 50000 or r.amount_vnd <> 500000 then raise exception 'FAIL: 쿠폰 할인 계산 %/%', r.discount_vnd, r.amount_vnd; end if;
  -- 정상: 취소 — 취소 시각을 과거로 보내도 서버가 지금으로 고친다
  update public.bookings set status = 'cancelled', cancelled_at = now() - interval '2 days', cancel_reason = '일정 변경', cancelled_by = 'customer'
   where id = '00000000-0000-0000-0000-0000000000b2';
  select cancelled_at, status into r from public.bookings where id = '00000000-0000-0000-0000-0000000000b2';
  if r.status <> 'cancelled' or r.cancelled_at < now() - interval '1 minute' then raise exception 'FAIL: 손님 취소 결과 %', r; end if;
  -- 정상: 새 예약(수수료율을 0 으로 보내도 서버 값으로 바뀐다)
  insert into public.bookings (customer_id, provider_id, service_id, scheduled_at, location_type, status, payment_method, amount_vnd, fee_rate)
  values ('00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000f1', (select id from public.services limit 1),
          now() + interval '1 day', 'hotel', 'confirmed', 'card_onsite', 500000, 0)
  returning fee_rate into r;
  if r.fee_rate is distinct from public.fee_rate_of('00000000-0000-0000-0000-0000000000f1') then raise exception 'FAIL: 수수료율 %', r.fee_rate; end if;
  -- 제공자 신청 INSERT: 승인·인증 상태로는 못 만든다
  begin
    insert into public.providers (profile_id, display_name, application_status, is_active) values ('00000000-0000-0000-0000-0000000000e1', 'x', 'approved', true);
    raise exception 'FAIL: 손님이 승인 상태로 제공자를 만듦';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.providers (profile_id, display_name, application_status, is_verified, fee_tier) values ('00000000-0000-0000-0000-0000000000e1', 'x', 'pending', true, 'freelancer');
    raise exception 'FAIL: 손님이 인증·등급을 단 신청을 만듦';
  exception when insufficient_privilege then null; end;
  insert into public.providers (profile_id, kind, display_name, specialties, is_active, application_status, rating, review_count)
  values ('00000000-0000-0000-0000-0000000000e1', 'masseur', '신청자', array['aroma'], false, 'pending', 0, 0);
end $$;

-- ── 예약 제한 손님 ──
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-0000000000e2", "role": "authenticated"}', true);
do $$
begin
  begin
    insert into public.bookings (customer_id, provider_id, service_id, scheduled_at, location_type, status, payment_method, amount_vnd)
    values ('00000000-0000-0000-0000-0000000000e2', '00000000-0000-0000-0000-0000000000f1', (select id from public.services limit 1),
            now() + interval '1 day', 'hotel', 'confirmed', 'card_onsite', 500000);
    raise exception 'FAIL: 예약 제한 손님이 예약을 만듦';
  exception when insufficient_privilege then
    if sqlerrm not like '%제한%' then raise exception 'FAIL: 제한 안내 문구가 다름: %', sqlerrm; end if;
  end;
end $$;

-- ── 마사지사(P·P2 소유) ──
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-0000000000e3", "role": "authenticated"}', true);
do $$
declare r record; j jsonb;
begin
  begin update public.providers set is_verified = true where id = '00000000-0000-0000-0000-0000000000f1';
    raise exception 'FAIL: 마사지사가 인증 표시를 켬'; exception when insufficient_privilege then null; end;
  begin update public.providers set fee_tier = 'freelancer' where id = '00000000-0000-0000-0000-0000000000f1';
    raise exception 'FAIL: 마사지사가 수수료 등급을 바꿈'; exception when insufficient_privilege then null; end;
  begin update public.providers set penalty_level = 0 where id = '00000000-0000-0000-0000-0000000000f1';
    raise exception 'FAIL: 마사지사가 제재 단계를 지움'; exception when insufficient_privilege then null; end;
  begin update public.providers set suspended_until = null where id = '00000000-0000-0000-0000-0000000000f1';
    raise exception 'FAIL: 마사지사가 정지 기록을 지움'; exception when insufficient_privilege then null; end;
  begin update public.providers set rating = 5, review_count = 99 where id = '00000000-0000-0000-0000-0000000000f1';
    raise exception 'FAIL: 마사지사가 평점을 바꿈'; exception when insufficient_privilege then null; end;
  begin update public.providers set application_status = 'approved' where id = '00000000-0000-0000-0000-0000000000f2';
    raise exception 'FAIL: 마사지사가 자기 신청을 승인함'; exception when insufficient_privilege then null; end;
  begin update public.bookings set amount_vnd = 1 where id = '00000000-0000-0000-0000-0000000000b1';
    raise exception 'FAIL: 마사지사가 예약 금액을 바꿈'; exception when insufficient_privilege then null; end;
  begin update public.bookings set is_paid = true where id = '00000000-0000-0000-0000-0000000000b1';
    raise exception 'FAIL: 마사지사가 결제 완료로 바꿈'; exception when insufficient_privilege then null; end;
  begin update public.bookings set rejected_at = null where id = '00000000-0000-0000-0000-0000000000b5';
    raise exception 'FAIL: 마사지사가 거절 기록을 지움'; exception when insufficient_privilege then null; end;

  -- 정상: 프로필·사진·영업시간·출근·위치
  update public.providers set display_name = '새 이름', bio = '소개', photo_url = 'https://x/1.jpg', photo_urls = array['https://x/1.jpg'],
         service_area = '바딘', phone = '0900', business_hours = '10:00 ~ 22:00', is_active = false,
         lat = 21.0, lng = 105.8, last_lat = 21.0, last_lng = 105.8, last_seen_at = now()
   where id = '00000000-0000-0000-0000-0000000000f1';
  if not found then raise exception 'FAIL: 마사지사 프로필 수정 안 됨'; end if;
  update public.providers set is_active = true where id = '00000000-0000-0000-0000-0000000000f1';
  -- 정상: 반려된 신청 재제출
  update public.providers set application_status = 'pending', reject_reason = null, display_name = '재제출'
   where id = '00000000-0000-0000-0000-0000000000f2';
  if (select application_status::text from public.providers where id = '00000000-0000-0000-0000-0000000000f2') <> 'pending' then
    raise exception 'FAIL: 재제출 안 됨'; end if;
  -- 정상: 예약 수락·완료·노쇼·거절
  update public.bookings set status = 'completed', completed_at = now() where id = '00000000-0000-0000-0000-0000000000b1';
  if not found then raise exception 'FAIL: 완료 처리 안 됨'; end if;
  update public.bookings set status = 'cancelled', no_show_at = now(), cancelled_by = 'provider', cancel_reason = '고객 노쇼'
   where id = '00000000-0000-0000-0000-0000000000b4';
  if (select no_show_at from public.bookings where id = '00000000-0000-0000-0000-0000000000b4') is null then raise exception 'FAIL: 노쇼 처리 안 됨'; end if;
  -- 정상: 거절 누적 재계산은 서버 함수로(거절 1건 → 0단계, 관리자 하한 2단계 아래로는 낮추지 않는다)
  j := public.refresh_provider_penalty('00000000-0000-0000-0000-0000000000f1');
  select reject_count, penalty_level into r from public.providers where id = '00000000-0000-0000-0000-0000000000f1';
  if r.reject_count <> 1 or r.penalty_level <> 2 or (j->>'count')::int <> 1 then raise exception 'FAIL: 거절 재계산 % %', r, j; end if;
end $$;

-- 남의 제공자 제재 재계산은 못 한다
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-0000000000e1", "role": "authenticated"}', true);
do $$
begin
  perform public.refresh_provider_penalty('00000000-0000-0000-0000-0000000000f1');
  raise exception 'FAIL: 관계없는 사람이 제공자 제재를 재계산함';
exception when insufficient_privilege then null;
end $$;

-- 정지 중에는 스스로 다시 켤 수 없다
reset role;
update public.providers set suspended_until = now() + interval '2 days', is_active = false where id = '00000000-0000-0000-0000-0000000000f1';
set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-0000000000e3", "role": "authenticated"}', true);
do $$
begin
  update public.providers set is_active = true where id = '00000000-0000-0000-0000-0000000000f1';
  raise exception 'FAIL: 정지 중인 마사지사가 스스로 다시 켬';
exception when insufficient_privilege then null;
end $$;

-- ── 관리자: 전부 그대로 된다 ──
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-0000000000e4", "role": "authenticated"}', true);
do $$
begin
  update public.bookings set is_paid = true, amount_vnd = 450000, no_show_at = null where id = '00000000-0000-0000-0000-0000000000b3';
  if not found then raise exception 'FAIL: 관리자 예약 수정 안 됨'; end if;
  update public.providers set is_verified = true, fee_tier = 'shop', penalty_level = 0, suspended_until = null, reject_count = 0,
         application_status = 'approved', is_active = true where id = '00000000-0000-0000-0000-0000000000f2';
  if not found then raise exception 'FAIL: 관리자 제공자 수정 안 됨'; end if;
  update public.providers set penalty_level = 0, suspended_until = null, is_active = true where id = '00000000-0000-0000-0000-0000000000f1';
  insert into public.bookings (customer_id, provider_id, service_id, scheduled_at, location_type, status, payment_method, amount_vnd)
  values ('00000000-0000-0000-0000-0000000000e4', '00000000-0000-0000-0000-0000000000f1', (select id from public.services limit 1),
          now() + interval '1 day', 'hotel', 'confirmed', 'card_onsite', 500000);
end $$;
reset role;

do $$
begin
  if (select is_verified from public.providers where id = '00000000-0000-0000-0000-0000000000f1') then
    raise exception 'FAIL: 결과 — P 가 인증됨'; end if;
  if (select is_paid from public.bookings where id = '00000000-0000-0000-0000-0000000000b3') is not true then
    raise exception 'FAIL: 결과 — 관리자 결제 표시가 안 남음'; end if;
end $$;

select 'ALL PASS' as result;
rollback;
