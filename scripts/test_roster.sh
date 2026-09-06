#!/bin/sh
# 명단·페이백이 실제로 맞게 도는지 확인한다. 시험 흔적은 끝에 지운다.
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
\set ON_ERROR_STOP off
select id as adm from public.profiles where role='admin' limit 1 \gset
select id as cus from public.profiles where role='customer' limit 1 \gset
select id as pv  from public.providers where application_status='approved' order by created_at limit 1 \gset

\echo '=== 1. 전원 10% 로 맞춰졌는가 ==='
select fee_tier::text as 등급, count(*) from public.providers group by 1;
select '  새로 승인될 사람의 기본값 = ' || column_default as 확인
  from information_schema.columns
 where table_schema='public' and table_name='providers' and column_name='fee_tier';

\echo '=== 2. 명단이 나오는가 ==='
begin;
 select set_config('request.jwt.claims', json_build_object('sub', :'adm')::text, true);
 select jsonb_array_length((public.admin_provider_list())->'rows') as 명단수,
        (public.admin_provider_list())->'tiers' as 등급표;
commit;

\echo '=== 3. 미납 계산 근거를 만든다 (완료 예약 1건 100만, 10%) ==='
insert into public.bookings (customer_id, provider_id, service_id, status, amount_vnd, is_paid, scheduled_at, completed_at)
values (:'cus', :'pv', (select id from public.services limit 1), 'completed', 1000000, true, now(), now())
returning id as bk \gset
begin;
 select set_config('request.jwt.claims', json_build_object('sub', :'adm')::text, true);
 select r->>'name' as 이름, r->>'fee' as 발생수수료, r->>'credit' as 선입금잔액, r->>'owe' as 미납
   from jsonb_array_elements((public.admin_provider_list())->'rows') r
  where (r->>'id') = :'pv';
commit;

\echo '=== 4. 관리자가 페이백 200만 입력 (구간상 보너스 10% = 20만) ==='
begin;
 select set_config('request.jwt.claims', json_build_object('sub', :'adm')::text, true);
 select jsonb_pretty(public.admin_add_prepay(:'pv', 2000000, null, '시험 입력')) as 결과;
commit;

\echo '=== 5. 잔고가 220만이 되고 미납이 0으로 덮이는가 ==='
begin;
 select set_config('request.jwt.claims', json_build_object('sub', :'adm')::text, true);
 select r->>'fee' as 발생수수료, r->>'credit' as 선입금잔액, r->>'owe' as 미납,
        case when (r->>'credit')::bigint = 2200000 then '잔고 통과' else '★ 잔고 실패' end as 판정
   from jsonb_array_elements((public.admin_provider_list())->'rows') r
  where (r->>'id') = :'pv';
commit;

\echo '=== 6. 잔고에서 수수료 10만 차감 ==='
begin;
 select set_config('request.jwt.claims', json_build_object('sub', :'adm')::text, true);
 select public.admin_use_credit(:'pv', 100000, '시험 차감') as 남은잔고;
commit;

\echo '=== 7. 잔고보다 큰 금액은 막히는가 ==='
begin;
 select set_config('request.jwt.claims', json_build_object('sub', :'adm')::text, true);
 select public.admin_use_credit(:'pv', 999999999, '과다 차감');
rollback;

\echo '=== 8. 권한: 고객은 명단도 페이백도 못 한다 ==='
begin;
 select set_config('request.jwt.claims', json_build_object('sub', :'cus')::text, true);
 select public.admin_provider_list();
rollback;
begin;
 select set_config('request.jwt.claims', json_build_object('sub', :'cus')::text, true);
 select public.admin_add_prepay(:'pv', 1000000, null, '몰래');
rollback;

\echo '=== 9. 뒷정리 ==='
delete from public.provider_credit_tx where provider_id = :'pv';
delete from public.provider_credit    where provider_id = :'pv';
delete from public.provider_deposit   where provider_id = :'pv' and memo in ('시험 입력');
delete from public.bookings where id = :'bk';
select '  남은 예약 ' || count(*) || '건' as 확인 from public.bookings;
select '  남은 선입금 기록 ' || count(*) || '건' as 확인 from public.provider_deposit;
PSQL
