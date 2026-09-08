#!/bin/sh
# 계정이 연결된 마사지사가 정말 없는지 확인한다.
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
select application_status::text as 상태,
       count(*) as 전체,
       count(*) filter (where profile_id is not null) as profile_있음,
       count(*) filter (where owner_id   is not null) as owner_있음
  from public.providers group by 1 order by 2 desc;

\echo '--- 계정이 붙어 있는 마사지사 ---'
select display_name, application_status::text as 상태,
       left(coalesce(profile_id, owner_id)::text, 8) as 계정,
       case when profile_id is not null then 'profile' else 'owner' end as 어느칸
  from public.providers
 where coalesce(profile_id, owner_id) is not null
 order by created_at;
PSQL
