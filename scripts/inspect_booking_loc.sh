#!/bin/sh
# 예약에 방문 위치를 어떻게 저장하고 있는지 본다. 지도 연동을 붙이면 좌표를 남겨야 한다.
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
select column_name as 칸, data_type as 자료형
  from information_schema.columns
 where table_schema='public' and table_name='bookings'
   and (column_name like '%hotel%' or column_name like '%room%' or column_name like '%addr%'
        or column_name like '%lat%' or column_name like '%lng%' or column_name like '%loc%'
        or column_name like '%place%' or column_name like '%front%')
 order by column_name;

\echo '--- 지금까지 들어온 값 ---'
select coalesce(hotel_name,'(없음)') as 숙소, coalesce(room_number,'-') as 호수,
       location_type::text as 유형, count(*) as 건수
  from public.bookings group by 1,2,3 order by 4 desc limit 10;
PSQL
