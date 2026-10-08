-- 거절 제재 자동 회복·하한, 쿠폰함 잠금 시험. 전부 트랜잭션 안, 끝에 롤백한다(예약 INSERT 알림도 함께 사라진다).
\set ON_ERROR_STOP on
begin;

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000e1', 'pen-cust@test.massa'),
  ('00000000-0000-0000-0000-0000000000e3', 'pen-prov@test.massa'),
  ('00000000-0000-0000-0000-0000000000e4', 'pen-admin@test.massa'),
  ('00000000-0000-0000-0000-0000000000e5', 'pen-prov2@test.massa');
insert into public.profiles (id, full_name, role) values
  ('00000000-0000-0000-0000-0000000000e1', '손님', 'customer'),
  ('00000000-0000-0000-0000-0000000000e3', '마사지사', 'customer'),
  ('00000000-0000-0000-0000-0000000000e4', '관리자', 'admin'),
  ('00000000-0000-0000-0000-0000000000e5', '마사지사2', 'customer')
on conflict (id) do update set full_name = excluded.full_name, role = excluded.role;

-- Q1: 2단계(옛 거절만 남음) · Q2: 2단계(관리자 하한 예정) · Q3: 3단계 정지 중(최근 거절 12회)
insert into public.providers (id, profile_id, owner_id, display_name, application_status, is_active, penalty_level, suspended_until) values
  ('00000000-0000-0000-0000-0000000000f1', '00000000-0000-0000-0000-0000000000e3', null, 'Q1', 'approved', true, 2, null),
  ('00000000-0000-0000-0000-0000000000f2', null, '00000000-0000-0000-0000-0000000000e3', 'Q2', 'approved', true, 2, null),
  ('00000000-0000-0000-0000-0000000000f3', '00000000-0000-0000-0000-0000000000e5', null, 'Q3', 'approved', false, 3, now() + interval '1 day');
insert into public.bookings (customer_id, provider_id, scheduled_at, location_type, status, payment_method, amount_vnd, rejected_at)
select '00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000f1', now(), 'hotel', 'cancelled', 'card_onsite', 500000, now() - interval '40 days'
  from generate_series(1, 9);
insert into public.bookings (customer_id, provider_id, scheduled_at, location_type, status, payment_method, amount_vnd, rejected_at)
select '00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000f3', now(), 'hotel', 'cancelled', 'card_onsite', 500000, now() - interval '1 day'
  from generate_series(1, 12);
insert into public.bookings (id, customer_id, provider_id, service_id, scheduled_at, location_type, status, payment_method, amount_vnd) values
  ('00000000-0000-0000-0000-0000000000b1', '00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000f1', null, now() + interval '3 hours', 'hotel', 'confirmed', 'card_onsite', 500000);
insert into public.coupons (id, code, title, discount_type, discount_value, min_amount_vnd, is_active, valid_until) values
  ('00000000-0000-0000-0000-0000000000c1', 'PENT1', '시험쿠폰', 'percent', 10, 0, true, null),
  ('00000000-0000-0000-0000-0000000000c2', 'PENT2', '꺼진쿠폰', 'percent', 10, 0, false, null),
  ('00000000-0000-0000-0000-0000000000c3', 'PENT3', '지난쿠폰', 'percent', 10, 0, true, '2020-01-01');

set local role authenticated;

-- ── 쿠폰함(손님) ──
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-0000000000e1", "role": "authenticated"}', true);
do $$
begin
  insert into public.user_coupons (customer_id, coupon_id) values ('00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000c1');
  begin
    update public.user_coupons set is_used = true, used_at = now() where coupon_id = '00000000-0000-0000-0000-0000000000c1';
    update public.user_coupons set is_used = false, used_at = null where coupon_id = '00000000-0000-0000-0000-0000000000c1';
    raise exception 'FAIL: 손님이 쓴 쿠폰을 미사용으로 되돌림';
  exception when insufficient_privilege then null; end;
  begin
    delete from public.user_coupons where coupon_id = '00000000-0000-0000-0000-0000000000c1';
    raise exception 'FAIL: 손님이 쿠폰함 행을 지움';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.user_coupons (customer_id, coupon_id) values ('00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000c2');
    raise exception 'FAIL: 꺼진 쿠폰을 받음';
  exception when insufficient_privilege then null; end;
  begin
    insert into public.user_coupons (customer_id, coupon_id) values ('00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000c3');
    raise exception 'FAIL: 기한 지난 쿠폰을 받음';
  exception when insufficient_privilege then null; end;
  begin
    update public.user_coupons set coupon_id = '00000000-0000-0000-0000-0000000000c3' where coupon_id = '00000000-0000-0000-0000-0000000000c1';
    raise exception 'FAIL: 받은 쿠폰을 다른 쿠폰으로 바꿈';
  exception when insufficient_privilege then null; end;
end $$;

-- 쿠폰을 예약에 붙이면 서버가 사용 처리한다. 구 앱의 사용 처리 호출은 0행으로 그냥 지나간다. 취소해도 복원하지 않는다(기존 규칙)
do $$
declare k integer;
begin
  update public.bookings set coupon_id = '00000000-0000-0000-0000-0000000000c1', discount_vnd = 50000
   where id = '00000000-0000-0000-0000-0000000000b1';
  if not (select is_used from public.user_coupons where coupon_id = '00000000-0000-0000-0000-0000000000c1') then
    raise exception 'FAIL: 쿠폰을 붙였는데 사용 처리가 안 됨'; end if;
  update public.user_coupons set is_used = true, used_at = now()
   where customer_id = '00000000-0000-0000-0000-0000000000e1' and coupon_id = '00000000-0000-0000-0000-0000000000c1' and is_used = false;
  get diagnostics k = row_count;
  if k <> 0 then raise exception 'FAIL: 구 앱 사용 처리 %행', k; end if;
  update public.bookings set status = 'cancelled', cancel_reason = 'x', cancelled_by = 'customer'
   where id = '00000000-0000-0000-0000-0000000000b1';
  if not (select is_used from public.user_coupons where coupon_id = '00000000-0000-0000-0000-0000000000c1') then
    raise exception 'FAIL: 취소 후 쿠폰 상태가 바뀜'; end if;
end $$;

-- ── 거절 제재(마사지사) ──
reset role;
update public.providers set penalty_floor = 0 where id in ('00000000-0000-0000-0000-0000000000f1', '00000000-0000-0000-0000-0000000000f3');
set local role authenticated;

-- 관리자가 Q2 에 신고 제재 2단계를 준다 → 하한 2
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-0000000000e4", "role": "authenticated"}', true);
update public.providers set penalty_level = 2 where id = '00000000-0000-0000-0000-0000000000f2';
update public.providers set penalty_level = 1 where id = '00000000-0000-0000-0000-0000000000f2';
update public.providers set penalty_level = 2 where id = '00000000-0000-0000-0000-0000000000f2';
do $$
begin
  if (select penalty_floor from public.providers where id = '00000000-0000-0000-0000-0000000000f2') <> 2 then
    raise exception 'FAIL: 관리자 제재가 하한으로 안 남음'; end if;
end $$;

select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-0000000000e3", "role": "authenticated"}', true);
do $$
declare j jsonb;
begin
  -- 옛 거절(40일 전)만 있는 Q1 은 0단계로 회복
  j := public.refresh_provider_penalty('00000000-0000-0000-0000-0000000000f1');
  if (select penalty_level from public.providers where id = '00000000-0000-0000-0000-0000000000f1') <> 0 or (j->>'level')::int <> 0 then
    raise exception 'FAIL: 30일 지난 거절인데 회복 안 됨 %', j; end if;
  -- 관리자 하한 2 인 Q2 는 거절 0회여도 2단계 유지
  j := public.refresh_provider_penalty('00000000-0000-0000-0000-0000000000f2');
  if (select penalty_level from public.providers where id = '00000000-0000-0000-0000-0000000000f2') <> 2 then
    raise exception 'FAIL: 관리자 하한 아래로 내려감 %', j; end if;
  begin
    update public.providers set penalty_floor = 0 where id = '00000000-0000-0000-0000-0000000000f2';
    raise exception 'FAIL: 마사지사가 하한을 지움';
  exception when insufficient_privilege then null; end;
  begin
    perform public.apply_provider_penalty('00000000-0000-0000-0000-0000000000f2', false);
    raise exception 'FAIL: 앱에서 내부 계산 함수를 부름';
  exception when insufficient_privilege then null; end;
  begin
    perform public.refresh_all_provider_penalties();
    raise exception 'FAIL: 앱에서 전체 재계산을 부름';
  exception when insufficient_privilege then null; end;
end $$;

-- Q3: 정지 중 화면 열기(재계산)로는 정지가 늘지 않고, 방금 거절했을 때만 다시 3일
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-0000000000e5", "role": "authenticated"}', true);
do $$
declare before_ts timestamptz;
begin
  before_ts := (select suspended_until from public.providers where id = '00000000-0000-0000-0000-0000000000f3');
  perform public.refresh_provider_penalty('00000000-0000-0000-0000-0000000000f3');
  if (select suspended_until from public.providers where id = '00000000-0000-0000-0000-0000000000f3') <> before_ts then
    raise exception 'FAIL: 재계산만으로 정지가 연장됨'; end if;
  perform public.refresh_provider_penalty('00000000-0000-0000-0000-0000000000f3', true);
  if (select suspended_until from public.providers where id = '00000000-0000-0000-0000-0000000000f3') < now() + interval '71 hours' then
    raise exception 'FAIL: 새 거절 뒤 정지가 안 걸림'; end if;
end $$;

-- 관리자 제재 해제 → 하한 0 → 다음 재계산에서 데이터대로
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-0000000000e4", "role": "authenticated"}', true);
update public.providers set penalty_level = 0, suspended_until = null, reject_count = 0, is_active = true where id = '00000000-0000-0000-0000-0000000000f2';
reset role;

-- 매일 도는 전체 재계산(postgres)
do $$
declare k integer;
begin
  update public.providers set penalty_level = 2 where id = '00000000-0000-0000-0000-0000000000f1';  -- 서버 경로라 하한은 그대로 0
  k := public.refresh_all_provider_penalties();
  if k < 2 then raise exception 'FAIL: 전체 재계산 대상 %', k; end if;
  if (select penalty_level from public.providers where id = '00000000-0000-0000-0000-0000000000f1') <> 0
     or (select penalty_floor from public.providers where id = '00000000-0000-0000-0000-0000000000f2') <> 0
     or (select penalty_level from public.providers where id = '00000000-0000-0000-0000-0000000000f3') <> 3 then
    raise exception 'FAIL: 전체 재계산 결과가 다름'; end if;
end $$;

select 'ALL PASS' as result;
rollback;
