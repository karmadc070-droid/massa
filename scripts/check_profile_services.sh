#!/bin/sh
# 프로필에 내린 코스가 얼마나 보이고 있었는지, 고친 뒤에도 빈 프로필이 생기지 않는지 확인한다.
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
\echo '=== 마사지사에게 붙어 있는 내린 코스 (이게 프로필에 보이고 있었다) ==='
select s.name as 코스, count(*) as 붙어있는_마사지사
  from public.provider_services ps
  join public.services s on s.id = ps.service_id
 where not s.is_active
 group by 1 order by 2 desc, 1;

\echo '=== 전체 연결 중 내린 코스 비율 ==='
select count(*) filter (where s.is_active) as 활성,
       count(*) filter (where not s.is_active) as 내림,
       round(100.0 * count(*) filter (where not s.is_active) / nullif(count(*),0), 1) as 내림비율
  from public.provider_services ps join public.services s on s.id = ps.service_id;

\echo '=== 고친 뒤 프로필이 비는 마사지사가 생기는가 (0 이어야 한다) ==='
select count(*) as 빈_프로필
  from public.providers p
 where p.is_active and p.application_status = 'approved'
   and not exists (
     select 1 from public.provider_services ps
       join public.services s on s.id = ps.service_id and s.is_active
      where ps.provider_id = p.id);
PSQL
