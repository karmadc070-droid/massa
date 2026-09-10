#!/bin/sh
# 실제 거리를 계산하려면 마사지사 좌표가 있어야 한다. 몇 명이나 가지고 있는지 본다.
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
\echo '=== providers 위치 관련 칸 ==='
select column_name, data_type
  from information_schema.columns
 where table_schema='public' and table_name='providers'
   and (column_name like '%lat%' or column_name like '%lng%' or column_name like '%lon%'
        or column_name like '%district%' or column_name like '%area%' or column_name like '%gps%')
 order by column_name;

\echo '=== 좌표를 가진 마사지사 ==='
select case when lat is not null and lng is not null then '좌표 있음' else '좌표 없음' end as 구분,
       count(*) as 명수
  from public.providers
 where is_active and application_status='approved'
 group by 1 order by 2 desc;

\echo '=== 좌표 값 훑어보기 (하노이는 대략 위도 21.0 · 경도 105.8) ==='
select display_name as 이름, round(lat::numeric,5) as 위도, round(lng::numeric,5) as 경도,
       coalesce(base_district,'-') as 권역,
       round(last_lat::numeric,5) as 최근위도, round(last_lng::numeric,5) as 최근경도
  from public.providers
 where is_active and application_status='approved' and lat is not null
 order by display_name limit 25;

\echo '=== 좌표가 서로 다른가 (같으면 시드) ==='
select count(*) as 전체, count(distinct (lat, lng)) as 서로다른좌표
  from public.providers where is_active and application_status='approved' and lat is not null;

\echo '=== 사진 장수 ==='
select coalesce(array_length(photo_urls,1),0) as 사진수, count(*) as 명수
  from public.providers
 where is_active and application_status='approved'
 group by 1 order by 1;
PSQL
