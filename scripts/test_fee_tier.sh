#!/bin/sh
# 수수료 등급이 실제로 굳는지 확인한다. 시험 데이터는 끝에 전부 지운다.
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
\set ON_ERROR_STOP off
select id as adm from public.profiles where role='admin' limit 1 \gset
select id as cus from public.profiles where role='customer' limit 1 \gset
select id as pv1 from public.providers where application_status='approved' order by created_at limit 1 \gset
select id as sv1 from public.services limit 1 \gset

\echo '=== 1. 초기값: 전원 프리랜서 20% 여야 한다 ==='
select fee_tier::text, count(*) from public.providers group by 1;
select '  요율 조회 = ' || public.fee_rate_of(:'pv1') as 확인;

\echo '=== 2. 기존 예약 7건은 10% 로 굳어 있어야 한다 ==='
select coalesce(fee_rate::text,'(비어있음)') as 요율, count(*) from public.bookings group by 1;

\echo '=== 3. 새 예약을 넣으면 지금 요율(20%)이 박힌다 ==='
insert into public.bookings (customer_id, provider_id, service_id, status, amount_vnd, is_paid, scheduled_at, completed_at)
values (:'cus', :'pv1', :'sv1', 'completed', 1000000, true, now(), now())
returning id as bk1, fee_rate as rate1 \gset
select '  새 예약 요율 = ' || :'rate1' as 확인;

\echo '=== 4. 등급을 우대(10%)로 바꾼다 ==='
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'adm')::text, true);
  select public.set_fee_tier(:'pv1', 'vip');
commit;
select '  바뀐 등급 = ' || fee_tier::text || ' · 새 요율 = ' || public.fee_rate_of(id)
  from public.providers where id = :'pv1';

\echo '=== 5. ★ 아까 넣은 예약의 요율은 그대로 20% 여야 한다 (핵심) ==='
select case when fee_rate = 0.20 then '  통과 — 과거 예약이 움직이지 않았다 (0.20)'
            else '  ★ 실패 — ' || fee_rate::text end as 결과
  from public.bookings where id = :'bk1';

\echo '=== 6. 등급 바꾼 뒤 새 예약은 10% 로 박힌다 ==='
insert into public.bookings (customer_id, provider_id, service_id, status, amount_vnd, is_paid, scheduled_at, completed_at)
values (:'cus', :'pv1', :'sv1', 'completed', 1000000, true, now(), now())
returning id as bk2, fee_rate as rate2 \gset
select '  두 번째 예약 요율 = ' || :'rate2' as 확인;

\echo '=== 7. 정산이 예약별 요율로 계산되는가 (20% 1건 + 10% 1건 = 30만) ==='
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'adm')::text, true);
  select public.close_settlement_cycle('test', current_date, current_date) as 마감건수;
commit;
select '  총액 ' || gross_vnd || ' · 수수료 ' || fee_vnd ||
       case when fee_vnd = 300000 then '  → 통과 (200,000 + 100,000)'
            else '  → ★ 실패, 300000 이어야 한다' end as 결과
  from public.settlement_cycle
 where provider_id = :'pv1' and period_type = 'test';

\echo '=== 8. 권한: 일반 고객은 목록도 등급 변경도 못 한다 ==='
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'cus')::text, true);
  select public.admin_provider_fees();
rollback;
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'cus')::text, true);
  select public.set_fee_tier(:'pv1', 'vip');
rollback;

\echo '=== 9. 관리자 목록 (앞 2명) ==='
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'adm')::text, true);
  select jsonb_pretty((public.admin_provider_fees())->'tiers') as 등급요율,
         jsonb_array_length((public.admin_provider_fees())->'rows') as 명단수;
commit;

\echo '=== 10. 뒷정리 ==='
delete from public.settlement_cycle where period_type = 'test';
delete from public.bookings where id in (:'bk1', :'bk2');
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'adm')::text, true);
  select public.set_fee_tier(:'pv1', 'freelancer');
commit;
select '  남은 예약 ' || count(*) || '건 · 요율 분포' from public.bookings;
select coalesce(fee_rate::text,'(비어있음)') as 요율, count(*) from public.bookings group by 1;
PSQL
