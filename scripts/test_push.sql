-- 푸시 알림 시험: 토큰 RPC 권한·주인 이동, 예약 이벤트별 알림 생성, 공지 권한, 발송 대기열을 한 번만 내주는지. 트랜잭션 안에서 하고 끝에 되돌린다.
-- 실행: docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < scripts/test_push.sql

begin;

-- 시험이 providers 를 새로 만드는데 중복 신청 방지 트리거(Z-19)가 막을 수 있다. 시험 동안만 끈다(rollback 이면 같이 되돌아간다).
alter table providers disable trigger user;

-- 시험용 사용자: 손님 c, 마사지사 계정 o(owner_id)·p(profile_id), 남 x
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-00000000c001', 'push-c@test.massa'),
  ('00000000-0000-0000-0000-00000000c002', 'push-o@test.massa'),
  ('00000000-0000-0000-0000-00000000c003', 'push-p@test.massa'),
  ('00000000-0000-0000-0000-00000000c004', 'push-x@test.massa');
insert into profiles (id, role) values
  ('00000000-0000-0000-0000-00000000c001', 'customer'),
  ('00000000-0000-0000-0000-00000000c002', 'provider'),
  ('00000000-0000-0000-0000-00000000c003', 'provider'),
  ('00000000-0000-0000-0000-00000000c004', 'customer');
insert into providers (id, display_name, owner_id, profile_id) values
  ('00000000-0000-0000-0000-00000000d001', 'push test', '00000000-0000-0000-0000-00000000c002', '00000000-0000-0000-0000-00000000c003');

-- ── 1. 토큰 RPC ──────────────────────────────────────
set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-00000000c001", "role": "authenticated"}', true);
select public.register_push_token(repeat('a', 64), 'ios', 'vi');

do $$
begin
  begin
    perform 1 from public.push_tokens;
    raise exception 'FAIL: 앱 사용자가 push_tokens 를 직접 읽음';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.register_push_token(repeat('b', 64), 'android', 'vi');
    raise exception 'FAIL: 지원하지 않는 플랫폼 저장됨';
  exception when check_violation then null;
  end;
  begin
    perform public.register_push_token(repeat('b', 64), 'ios', 'fr');
    raise exception 'FAIL: 지원하지 않는 언어 저장됨';
  exception when check_violation then null;
  end;
  begin
    perform public.claim_unpushed_notifications();
    raise exception 'FAIL: 앱 사용자가 claim_unpushed_notifications 실행';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.send_notice('t', 'b');
    raise exception 'FAIL: 일반 회원이 공지를 보냄';
  exception when insufficient_privilege then null;
  end;
end $$;

-- 같은 기기에서 x 로 로그인하면 토큰 주인이 x 로 바뀐다. 이제 c 는 그 토큰을 못 지운다.
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-00000000c004", "role": "authenticated"}', true);
select public.register_push_token(repeat('a', 64), 'ios', 'ko');
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-00000000c001", "role": "authenticated"}', true);
select public.unregister_push_token(repeat('a', 64));
reset role;

do $$
begin
  if (select user_id::text || '/' || lang from public.push_tokens where token = repeat('a', 64))
     <> '00000000-0000-0000-0000-00000000c004/ko' then
    raise exception 'FAIL: 토큰 주인·언어가 바뀌지 않았거나 남이 지움';
  end if;
end $$;

-- x 는 자기 토큰을 지울 수 있다. 로그인 안 한 사람은 등록할 수 없다.
set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-00000000c004", "role": "authenticated"}', true);
select public.unregister_push_token(repeat('a', 64));
reset role;
do $$
begin
  if exists (select 1 from public.push_tokens where token = repeat('a', 64)) then
    raise exception 'FAIL: 본인 토큰이 지워지지 않음';
  end if;
end $$;
set local role anon;
do $$
begin
  begin
    perform public.register_push_token(repeat('c', 64), 'ios', 'vi');
    raise exception 'FAIL: anon 이 토큰 등록';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

-- ── 2. 예약 이벤트 → 알림 ─────────────────────────────
-- 손님이 앱에서 예약하듯 RLS 를 거쳐 넣는다(앱은 'confirmed' 로 바로 넣는다).
select count(*) as q_before from net.http_request_queue where url like '%/send-push' \gset
set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-00000000c001", "role": "authenticated"}', true);
insert into bookings (id, customer_id, provider_id, scheduled_at, status, amount_vnd)
values ('00000000-0000-0000-0000-00000000b001', '00000000-0000-0000-0000-00000000c001',
        '00000000-0000-0000-0000-00000000d001', '2026-10-09 07:00+00', 'confirmed', 500000);
reset role;

do $$
declare want int := 2 + (select count(*) from profiles where role = 'admin');
begin
  if (select count(*) from notifications where booking_id = '00000000-0000-0000-0000-00000000b001' and kind = 'booking_new') <> want then
    raise exception 'FAIL: 새 예약 알림 수가 다름 (기대 %)', want;
  end if;
  if not exists (select 1 from notifications where user_id = '00000000-0000-0000-0000-00000000c002' and kind = 'booking_new')
     or not exists (select 1 from notifications where user_id = '00000000-0000-0000-0000-00000000c003' and kind = 'booking_new') then
    raise exception 'FAIL: owner_id·profile_id 계정 중 알림을 못 받은 쪽이 있음';
  end if;
  if exists (select 1 from notifications where user_id = '00000000-0000-0000-0000-00000000c001') then
    raise exception 'FAIL: 예약한 손님에게 새 예약 알림이 감';
  end if;
  if (select body from notifications where user_id = '00000000-0000-0000-0000-00000000c002')
     <> (select booking_no from bookings where id = '00000000-0000-0000-0000-00000000b001') || ' · 10/09 14:00' then
    raise exception 'FAIL: 본문이 예약번호·하노이 시각이 아님';
  end if;
end $$;

-- 상태와 무관한 수정은 알림을 만들지 않는다. 출발·완료는 손님에게 간다.
update bookings set is_paid = true where id = '00000000-0000-0000-0000-00000000b001';
update bookings set status = 'on_the_way' where id = '00000000-0000-0000-0000-00000000b001';
update bookings set status = 'completed', completed_at = now() where id = '00000000-0000-0000-0000-00000000b001';
-- 요청 → 확정, 손님 본인 취소는 손님에게는 없고 마사지사에게 간다
insert into bookings (id, customer_id, provider_id, scheduled_at, status, amount_vnd) values
  ('00000000-0000-0000-0000-00000000b002', '00000000-0000-0000-0000-00000000c001', '00000000-0000-0000-0000-00000000d001', now() + interval '1 day', 'requested', 500000),
  ('00000000-0000-0000-0000-00000000b003', '00000000-0000-0000-0000-00000000c001', '00000000-0000-0000-0000-00000000d001', now() + interval '1 day', 'requested', 500000);
update bookings set status = 'confirmed' where id = '00000000-0000-0000-0000-00000000b002';
-- 손님 취소는 앱처럼 손님 권한(RLS)으로 한다
set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-00000000c001", "role": "authenticated"}', true);
update bookings set status = 'cancelled', cancelled_by = 'customer' where id = '00000000-0000-0000-0000-00000000b002';
reset role;
-- 마사지사 거절(cancelled_by 비어 있음)은 손님에게 간다
update bookings set status = 'cancelled', rejected_at = now() where id = '00000000-0000-0000-0000-00000000b003';

do $$
declare got text;
begin
  select string_agg(kind || ':' || right(booking_id::text, 4), ',' order by kind) into got
  from notifications where user_id = '00000000-0000-0000-0000-00000000c001';
  if got is distinct from 'booking_cancelled:b003,booking_completed:b001,booking_confirmed:b002,booking_on_the_way:b001' then
    raise exception 'FAIL: 손님 알림이 기대와 다름: %', got;
  end if;
  -- 손님 본인 취소(b002)는 마사지사 계정 둘 다에게 간다. 거절(b003)은 마사지사에게 가지 않는다
  if (select count(*) from notifications where kind = 'booking_cancelled_by_customer'
      and booking_id = '00000000-0000-0000-0000-00000000b002'
      and user_id in ('00000000-0000-0000-0000-00000000c002', '00000000-0000-0000-0000-00000000c003')) <> 2
     or exists (select 1 from notifications where kind = 'booking_cancelled_by_customer'
                and (booking_id <> '00000000-0000-0000-0000-00000000b002'
                     or user_id not in ('00000000-0000-0000-0000-00000000c002', '00000000-0000-0000-0000-00000000c003'))) then
    raise exception 'FAIL: 손님 취소 알림이 마사지사 계정 둘에게만 정확히 가지 않음';
  end if;
  if (select body from notifications where kind = 'booking_cancelled_by_customer' and user_id = '00000000-0000-0000-0000-00000000c002')
     not like 'MS-% · __/__ __:__' then
    raise exception 'FAIL: 손님 취소 알림 본문에 예약번호·시각이 없음';
  end if;
end $$;

-- 알림이 생기면 발송 함수 호출이 pg_net 대기열에 쌓인다
select count(*) as q_after from net.http_request_queue where url like '%/send-push' \gset
select (:q_after > :q_before) as kick_queued \gset
\if :kick_queued
\else
  select 1/0 as "FAIL: send-push 호출이 대기열에 없음";
\endif

-- ── 3. 공지 ──────────────────────────────────────────
select id as adm from profiles where role = 'admin' limit 1 \gset
set local role authenticated;
select set_config('request.jwt.claims', json_build_object('sub', :'adm', 'role', 'authenticated')::text, true);
select public.send_notice('  점검 안내  ', '오늘 밤 점검') as notice_rows \gset
reset role;
do $$
begin
  if (select count(*) from notifications where kind = 'notice' and title = '점검 안내' and body = '오늘 밤 점검') <> (select count(*) from profiles) then
    raise exception 'FAIL: 공지가 전 회원에게 들어가지 않음';
  end if;
end $$;
select (:notice_rows = (select count(*) from profiles)) as notice_count_ok \gset
\if :notice_count_ok
\else
  select 1/0 as "FAIL: send_notice 반환값이 회원 수와 다름";
\endif

-- ── 4. 발송 대기열은 한 번만 내준다 ─────────────────────
create temp table t_first as select id from public.claim_unpushed_notifications();
do $$
begin
  if (select count(*) from t_first f join notifications n using (id)
      where n.user_id in ('00000000-0000-0000-0000-00000000c001', '00000000-0000-0000-0000-00000000c002')) <> 10 then  -- 손님 4+공지 1, 마사지사 새 예약 3+손님 취소 1+공지 1
    raise exception 'FAIL: 첫 claim 이 시험 알림을 다 돌려주지 않음';
  end if;
  if exists (select 1 from public.claim_unpushed_notifications()) then
    raise exception 'FAIL: 같은 알림을 두 번 돌려줌';
  end if;
end $$;
-- 한 시간 넘게 묵은 알림은 내주지 않는다
insert into notifications (user_id, title, kind, created_at) values ('00000000-0000-0000-0000-00000000c001', 'old', 'notice', now() - interval '2 hours');
do $$
begin
  if exists (select 1 from public.claim_unpushed_notifications()) then
    raise exception 'FAIL: 묵은 알림을 돌려줌';
  end if;
end $$;

select 'ALL PASS' as result;

rollback;
