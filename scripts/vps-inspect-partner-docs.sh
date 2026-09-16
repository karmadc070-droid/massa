#!/bin/sh
# 서류(provider_kyc)가 빠진 파트너가 누구인지 본다. 읽기만 한다.
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=0 <<'SQL'
\pset pager off
\echo '=== provider_kyc 의 칸 ==='
select string_agg(column_name || ' ' || data_type, ', ' order by ordinal_position)
  from information_schema.columns
 where table_schema='public' and table_name='provider_kyc';

\echo ''
\echo '=== 승인된 22명 중 서류 레코드가 아예 없는 사람 ==='
select p.display_name, p.base_district, p.kind,
       to_char(p.created_at,'MM-DD') as 가입,
       coalesce(p.phone,'-') as 전화
  from public.providers p
  left join public.provider_kyc k on k.provider_id = p.id
 where p.application_status = 'approved' and k.provider_id is null
 order by p.created_at;

\echo ''
\echo '=== 서류 레코드는 있는 사람 (몇 명인가) ==='
select count(*) as 서류있음 from public.providers p
  join public.provider_kyc k on k.provider_id = p.id
 where p.application_status = 'approved';

\echo ''
\echo '=== 위생인증 현황 — 앱 설명에 약속한 배지다 ==='
select count(*) filter (where hygiene_certified) as 위생인증받음,
       count(*)                                  as 승인된파트너
  from public.providers where application_status='approved';
SQL
