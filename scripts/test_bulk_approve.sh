#!/bin/sh
# 일괄 승인이 실제로 여러 건을 처리하는지, 문제 있는 건만 걸러 내는지 확인한다.
# 시험 데이터는 끝에 전부 지운다.
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
\set ON_ERROR_STOP off
select id as adm from public.profiles where role='admin' limit 1 \gset
select id as cus from public.profiles where role='customer' limit 1 \gset
select p.id as pv1 from public.providers p
 where p.application_status='approved' and coalesce(p.profile_id,p.owner_id) is not null
 order by p.created_at limit 1 \gset

-- 이 마사지사가 하는 코스 3개
select ps.service_id as s1 from public.provider_services ps
  join public.services s on s.id=ps.service_id and s.is_active
 where ps.provider_id=:'pv1' order by s.name limit 1 offset 0 \gset
select ps.service_id as s2 from public.provider_services ps
  join public.services s on s.id=ps.service_id and s.is_active
 where ps.provider_id=:'pv1' order by s.name limit 1 offset 1 \gset
select ps.service_id as s3 from public.provider_services ps
  join public.services s on s.id=ps.service_id and s.is_active
 where ps.provider_id=:'pv1' order by s.name limit 1 offset 2 \gset

\echo ''
\echo '=== 준비: 대기 3건을 만든다 (2건은 정상, 1건은 상한 초과) ==='
insert into public.provider_price (provider_id, service_id, pending_vnd, requested_at)
select :'pv1', s.id, s.price_vnd + 50000, now() from public.services s where s.id in (:'s1', :'s2')
on conflict (provider_id, service_id) do update set pending_vnd = excluded.pending_vnd;
-- 상한을 넘는 값은 함수로는 못 넣으므로 직접 꽂는다 (요청 뒤 기준이 바뀐 상황을 흉내낸다)
insert into public.provider_price (provider_id, service_id, pending_vnd, requested_at)
select :'pv1', s.id, s.price_vnd * 5, now() from public.services s where s.id = :'s3'
on conflict (provider_id, service_id) do update set pending_vnd = excluded.pending_vnd;
select '  대기 ' || count(*) || '건' as 준비 from public.provider_price where pending_vnd is not null;

\echo ''
\echo '=== 1. 관리자가 아니면 거부돼야 한다 ==='
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'cus')::text, true);
  select public.admin_approve_prices('[]'::jsonb);
rollback;

\echo ''
\echo '=== 2. 3건을 한 번에 승인한다 → 2건 성공, 1건 실패해야 한다 ==='
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'adm')::text, true);
  select jsonb_pretty(public.admin_approve_prices(
    jsonb_build_array(
      jsonb_build_object('provider_id', :'pv1', 'service_id', :'s1'),
      jsonb_build_object('provider_id', :'pv1', 'service_id', :'s2'),
      jsonb_build_object('provider_id', :'pv1', 'service_id', :'s3'))
  )) as 결과;
commit;

\echo ''
\echo '=== 3. 결과 확인 — 정상 2건은 적용, 상한 초과 1건은 대기 그대로 ==='
select case when count(*) filter (where price_vnd is not null) = 2
             and count(*) filter (where pending_vnd is not null) = 1
            then '  통과 — 적용 2건 · 대기로 남음 1건'
            else '  ★ 실패 — 적용 ' || count(*) filter (where price_vnd is not null)
                 || ' · 대기 ' || count(*) filter (where pending_vnd is not null) end as 결과
  from public.provider_price where provider_id = :'pv1';

\echo ''
\echo '=== 4. 승인된 2건이 손님 목록에 나온다 ==='
select case when (select count(*) from jsonb_object_keys(
                    public.public_provider_prices() -> (:'pv1')::text)) = 2
            then '  통과 — 공개 목록에 2건' else '  ★ 실패' end as 결과;

\echo ''
\echo '=== 5. 빈 목록은 거부한다 ==='
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'adm')::text, true);
  select public.admin_approve_prices(null);
rollback;

\echo ''
\echo '=== 6. 뒷정리 ==='
delete from public.provider_price where provider_id = :'pv1';
select '  남은 개인 가격 ' || count(*) || '건 (0 이어야 한다)' as 확인 from public.provider_price;
PSQL
