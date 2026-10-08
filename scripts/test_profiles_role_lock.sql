-- profiles 권한 잠금 시험: 일반 회원은 role·노쇼/취소 제재를 못 바꾸고 이름 등은 바꿀 수 있다. 전부 트랜잭션 안, 끝에 롤백한다.
-- 예약 행은 넣지 않는다(예약 INSERT 트리거가 관리자 알림을 만든다). 제재 재계산은 "예약 0건 → 0회"로 확인한다.
\set ON_ERROR_STOP on
begin;

insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000d1', 'role-lock@test.massa'),
  ('00000000-0000-0000-0000-0000000000d2', 'role-lock-other@test.massa');
insert into public.profiles (id, full_name, cancel_count, no_show_count) values
  ('00000000-0000-0000-0000-0000000000d1', '시험', 3, 2),
  ('00000000-0000-0000-0000-0000000000d2', '남', 0, 0);

set local role authenticated;
select set_config('request.jwt.claims', '{"sub": "00000000-0000-0000-0000-0000000000d1", "role": "authenticated"}', true);
do $$
declare n integer;
begin
  begin
    update public.profiles set role = 'admin' where id = '00000000-0000-0000-0000-0000000000d1';
    raise exception 'FAIL: 일반 회원이 자기 role 을 바꿈';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.profiles set no_show_count = 0, cancel_count = 0 where id = '00000000-0000-0000-0000-0000000000d1';
    raise exception 'FAIL: 일반 회원이 노쇼·취소 횟수를 지움';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.profiles set booking_blocked_until = null where id = '00000000-0000-0000-0000-0000000000d1';
    raise exception 'FAIL: 일반 회원이 예약 제한을 풂';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.profiles (id, role) values ('00000000-0000-0000-0000-0000000000d1', 'admin')
      on conflict (id) do update set role = 'admin';
    raise exception 'FAIL: 일반 회원이 INSERT/UPSERT 로 role 을 바꿈';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.refresh_customer_penalty('00000000-0000-0000-0000-0000000000d2');
    raise exception 'FAIL: 관계없는 사람의 제재를 재계산함';
  exception when insufficient_privilege then null;
  end;

  update public.profiles set full_name = '새 이름', phone = '0900', gender = '기타', nationality = 'KR',
         terms_agreed_at = now(), privacy_agreed_at = now(), marketing_agreed_at = null, terms_version = 't'
   where id = '00000000-0000-0000-0000-0000000000d1';
  if not found then raise exception 'FAIL: 이름·전화·성별·국적·약관 수정 안 됨'; end if;

  n := public.refresh_customer_penalty('00000000-0000-0000-0000-0000000000d1');
  if n <> 0 then raise exception 'FAIL: 재계산 결과 %', n; end if;
end $$;
reset role;

do $$
begin
  if (select role::text from profiles where id = '00000000-0000-0000-0000-0000000000d1') <> 'customer'
     or (select full_name from profiles where id = '00000000-0000-0000-0000-0000000000d1') <> '새 이름'
     or (select cancel_count + no_show_count from profiles where id = '00000000-0000-0000-0000-0000000000d1') <> 0 then
    raise exception 'FAIL: 결과 값이 다름';
  end if;
end $$;

-- 서버 경로는 그대로 role 을 바꿀 수 있다
set local role service_role;
update public.profiles set role = 'admin' where id = '00000000-0000-0000-0000-0000000000d1';
reset role;
do $$
begin
  if (select role::text from profiles where id = '00000000-0000-0000-0000-0000000000d1') <> 'admin' then
    raise exception 'FAIL: 서버 role 변경 안 됨';
  end if;
end $$;

select 'ALL PASS' as result;
rollback;
