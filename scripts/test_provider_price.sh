#!/bin/sh
# 개인 가격이 실제로 막고, 승인돼야 보이고, 예약 금액을 서버가 덮어쓰는지 확인한다.
# 시험 데이터는 끝에 전부 지운다.
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
\set ON_ERROR_STOP off
select id as adm from public.profiles where role='admin' limit 1 \gset
select id as cus from public.profiles where role='customer' limit 1 \gset
-- 계정이 붙어 있는 마사지사를 고른다 (본인 확인 시험에 필요하다).
-- 승인된 21명 중 profile_id 를 가진 사람은 0명이고 owner_id 로만 붙어 있다. 둘 다 본다.
select p.id as pv1, coalesce(p.profile_id, p.owner_id) as own1
  from public.providers p
 where p.application_status='approved'
   and coalesce(p.profile_id, p.owner_id) is not null
 order by p.created_at limit 1 \gset
-- 그 마사지사가 실제로 하는 코스 하나
select ps.service_id as sv1, s.price_vnd as base1
  from public.provider_services ps join public.services s on s.id=ps.service_id
 where ps.provider_id = :'pv1' and s.is_active
 order by s.price_vnd limit 1 \gset

\echo ''
\echo '=== 0. 시험 대상 ==='
select '  마사지사 = ' || display_name from public.providers where id = :'pv1';
select '  코스 = ' || name || ' · 기본가 ' || price_vnd || ' · 상한 '
       || round(price_vnd * public.price_max_multiple())::int
  from public.services where id = :'sv1';

\echo ''
\echo '=== 1. 기본가보다 낮게 → 거부돼야 한다 ==='
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'own1')::text, true);
  select public.provider_set_price(:'pv1', :'sv1', (:base1 - 50000)::int);
rollback;

\echo ''
\echo '=== 2. 상한보다 높게 → 거부돼야 한다 ==='
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'own1')::text, true);
  select public.provider_set_price(:'pv1', :'sv1', (:base1 * 3)::int);
rollback;

\echo ''
\echo '=== 3. 남의 프로필 → 거부돼야 한다 ==='
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'cus')::text, true);
  select public.provider_set_price(:'pv1', :'sv1', (:base1 + 50000)::int);
rollback;

\echo ''
\echo '=== 4. 정상 범위(기본가 +100,000) → 대기로 들어간다 ==='
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'own1')::text, true);
  select '  ' || public.provider_set_price(:'pv1', :'sv1', (:base1 + 100000)::int) as 결과;
commit;
select case when price_vnd is null and pending_vnd = :base1 + 100000
            then '  통과 — 대기 ' || pending_vnd || ' · 적용가는 아직 없음'
            else '  ★ 실패 — 적용 ' || coalesce(price_vnd::text,'없음') || ' / 대기 ' || coalesce(pending_vnd::text,'없음') end as 결과
  from public.provider_price where provider_id = :'pv1' and service_id = :'sv1';

\echo ''
\echo '=== 5. ★ 승인 전에는 손님에게 안 보여야 한다 ==='
select case when (public.public_provider_prices() -> (:'pv1')::text) is null
            then '  통과 — 공개 목록에 없다'
            else '  ★ 실패 — 승인 전인데 노출됐다: ' || (public.public_provider_prices() -> (:'pv1')::text)::text end as 결과;

\echo ''
\echo '=== 6. ★ 승인 전 예약은 기본가로 잡혀야 한다 (화면이 부풀린 금액을 보내도) ==='
insert into public.bookings (customer_id, provider_id, service_id, status, amount_vnd, is_paid, scheduled_at, completed_at)
values (:'cus', :'pv1', :'sv1', 'completed', 9999999, true, now(), now())
returning id as bk1 \gset
select case when amount_vnd = :base1
            then '  통과 — 9,999,999 를 보냈지만 ' || amount_vnd || ' 로 덮어썼다'
            else '  ★ 실패 — ' || amount_vnd end as 결과
  from public.bookings where id = :'bk1';

\echo ''
\echo '=== 7. 관리자가 승인한다 ==='
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'adm')::text, true);
  select '  ' || public.admin_review_price(:'pv1', :'sv1', true) as 결과;
commit;
select case when price_vnd = :base1 + 100000 and pending_vnd is null
            then '  통과 — 적용가 ' || price_vnd
            else '  ★ 실패' end as 결과
  from public.provider_price where provider_id = :'pv1' and service_id = :'sv1';

\echo ''
\echo '=== 8. ★ 승인 뒤 예약은 개인 가격으로 잡혀야 한다 ==='
insert into public.bookings (customer_id, provider_id, service_id, status, amount_vnd, is_paid, scheduled_at, completed_at)
values (:'cus', :'pv1', :'sv1', 'completed', 1, true, now(), now())
returning id as bk2 \gset
select case when amount_vnd = :base1 + 100000
            then '  통과 — 1₫ 를 보냈지만 ' || amount_vnd || ' 로 덮어썼다'
            else '  ★ 실패 — ' || amount_vnd end as 결과
  from public.bookings where id = :'bk2';

\echo ''
\echo '=== 9. 이제 손님 목록에 보인다 ==='
select case when (public.public_provider_prices() #> array[(:'pv1')::text, (:'sv1')::text])::int = :base1 + 100000
            then '  통과 — 공개 목록에 ' || (public.public_provider_prices() #> array[(:'pv1')::text, (:'sv1')::text])::text
            else '  ★ 실패' end as 결과;

\echo ''
\echo '=== 10. 다른 마사지사는 그대로 기본가여야 한다 ==='
select case when public.effective_price(p.id, :'sv1') = :base1 then '  통과 — ' || p.display_name || ' 는 기본가 ' || :base1
            else '  ★ 실패' end as 결과
  from public.providers p
 where p.application_status='approved' and p.id <> :'pv1'
 order by p.created_at limit 1;

\echo ''
\echo '=== 11. 반려하면 대기가 지워지고 사유가 남는다 ==='
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'own1')::text, true);
  select public.provider_set_price(:'pv1', :'sv1', (:base1 + 150000)::int);
commit;
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'adm')::text, true);
  select '  ' || public.admin_review_price(:'pv1', :'sv1', false, '사진이 먼저 필요합니다') as 결과;
commit;
select case when pending_vnd is null and reject_reason = '사진이 먼저 필요합니다' and price_vnd = :base1 + 100000
            then '  통과 — 대기 지워짐 · 사유 남음 · 적용가는 그대로 ' || price_vnd
            else '  ★ 실패' end as 결과
  from public.provider_price where provider_id = :'pv1' and service_id = :'sv1';

\echo ''
\echo '=== 12. 비우면 기본가로 되돌아간다 ==='
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'own1')::text, true);
  select '  ' || public.provider_set_price(:'pv1', :'sv1', null) as 결과;
commit;
select case when public.effective_price(:'pv1', :'sv1') = :base1
            then '  통과 — 다시 기본가 ' || :base1 else '  ★ 실패' end as 결과;

\echo ''
\echo '=== 13. 뒷정리 ==='
delete from public.bookings where id in (:'bk1', :'bk2');
delete from public.provider_price where provider_id = :'pv1' and service_id = :'sv1';
select '  남은 개인 가격 ' || count(*) || '건 (0 이어야 한다)' as 확인 from public.provider_price;
select '  남은 예약 ' || count(*) || '건' as 확인 from public.bookings;
PSQL
