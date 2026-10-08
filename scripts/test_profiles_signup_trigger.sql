-- 가입 트리거 시험: 가입하면 profiles 가 customer 로 생기고(메타데이터 admin 무시), 백필 후 빠진 회원 0명, 알림 0건(push_outbox 테이블은 없다). 롤백한다.
-- 실행: sed 로 마이그레이션의 begin/commit 을 지운 본문을 /tmp/profiles_signup_body.sql 로 만든 뒤 이 파일을 돌린다.
\set ON_ERROR_STOP on
begin;

create temp table _before as
select (select count(*) from public.profiles where role = 'admin') as admins,
       (select count(*) from public.notifications) as notis;

\i /tmp/profiles_signup_body.sql

insert into auth.users (id, email, raw_user_meta_data) values
  ('00000000-0000-0000-0000-0000000000e1', 'signup-admin@test.massa', '{"role": "admin", "full_name": "가짜관리자"}'),
  ('00000000-0000-0000-0000-0000000000e2', 'signup-google@test.massa', '{"name": "구글이름"}');

do $$
begin
  if (select role::text from profiles where id = '00000000-0000-0000-0000-0000000000e1') is distinct from 'customer' then
    raise exception 'FAIL: 메타데이터 admin 가입자의 role 이 customer 가 아님';
  end if;
  if (select full_name from profiles where id = '00000000-0000-0000-0000-0000000000e1') <> '가짜관리자'
     or (select full_name from profiles where id = '00000000-0000-0000-0000-0000000000e2') <> '구글이름' then
    raise exception 'FAIL: 이름 매핑';
  end if;
  if exists (select 1 from auth.users u where not exists (select 1 from profiles p where p.id = u.id)) then
    raise exception 'FAIL: profiles 없는 회원이 남음';
  end if;
  if (select count(*) from profiles where role = 'admin') <> (select admins from _before) then
    raise exception 'FAIL: admin 수가 바뀜';
  end if;
  if (select count(*) from notifications) <> (select notis from _before) then
    raise exception 'FAIL: 알림 행이 생김';
  end if;
end $$;

-- 관리자 해제 RPC: 일반 회원은 거부
update profiles set cancel_count = 5, no_show_count = 2, booking_blocked_until = now() + interval '7 days'
 where id = '00000000-0000-0000-0000-0000000000e2';
set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-0000000000e1", "role": "authenticated"}', true);
do $$
begin
  begin
    perform public.admin_unblock_customer('00000000-0000-0000-0000-0000000000e2');
    raise exception 'FAIL: 일반 회원이 제한을 풂';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

-- 관리자는 해제 가능
update profiles set role = 'admin' where id = '00000000-0000-0000-0000-0000000000e1';
set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-0000000000e1", "role": "authenticated"}', true);
select public.admin_unblock_customer('00000000-0000-0000-0000-0000000000e2');
reset role;
do $$
begin
  if (select booking_blocked_until is not null or cancel_count + no_show_count <> 0
        from profiles where id = '00000000-0000-0000-0000-0000000000e2') then
    raise exception 'FAIL: 관리자 해제 안 됨';
  end if;
end $$;

select 'ALL PASS' as result;
rollback;
