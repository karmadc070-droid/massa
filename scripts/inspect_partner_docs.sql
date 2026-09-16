-- 서류가 빠진 파트너가 누구인지, 무엇이 비었는지 본다. 읽기만 한다.
\pset pager off

\echo '=== providers 표에서 서류로 볼 만한 칸 ==='
select column_name, data_type
  from information_schema.columns
 where table_schema='public' and table_name='providers'
   and (column_name ~* 'doc|cert|license|id_|verif|photo|file|attach|resume|career')
 order by ordinal_position;

\echo ''
\echo '=== 상태별 인원 ==='
select status, count(*) from public.providers group by status order by 2 desc;

\echo ''
\echo '=== 승인된 파트너의 서류 채움 현황 ==='
select
  count(*) as 전체,
  count(*) filter (where coalesce(cert_url,'') <> '')    as 자격증있음,
  count(*) filter (where coalesce(id_card_url,'') <> '') as 신분증있음,
  count(*) filter (where coalesce(photo_url,'') <> '')   as 사진있음
from public.providers
where status = 'approved';
