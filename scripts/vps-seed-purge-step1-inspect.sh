#!/bin/sh
# 지우기 전에 '무엇이 같이 딸려 오는가' 를 먼저 본다. 읽기만 한다.
# 예약을 지우면 채팅·정산 같은 자식 행이 같이 사라지거나, 반대로 제약에 막혀 실패한다.
# 모르고 지우면 둘 중 뭐가 일어났는지도 모른다.
SQL() { docker exec -i massa-db psql -U postgres -d postgres "$@" < /dev/null; }

echo '=== 1. bookings / reviews 를 참조하는 외래키 (지우면 영향받는 표) ==='
SQL -c "
select tc.table_name as child_table, kcu.column_name as child_col,
       ccu.table_name as parent_table, rc.delete_rule
from information_schema.table_constraints tc
join information_schema.key_column_usage kcu on kcu.constraint_name = tc.constraint_name
join information_schema.constraint_column_usage ccu on ccu.constraint_name = tc.constraint_name
join information_schema.referential_constraints rc on rc.constraint_name = tc.constraint_name
where tc.constraint_type = 'FOREIGN KEY'
  and ccu.table_name in ('bookings','reviews')
order by parent_table, child_table;"

echo ''
echo '=== 2. 지울 대상 건수 ==='
SQL -c "select (select count(*) from bookings) as bookings, (select count(*) from reviews) as reviews;"

echo ''
echo '=== 3. 그 예약에 달린 채팅이 있나 ==='
SQL -c "
select to_regclass('public.messages') as messages_table,
       to_regclass('public.chat_messages') as chat_messages_table,
       to_regclass('public.settlements') as settlements_table;"

echo ''
echo '=== 4. 후기가 예약을 참조하나 (booking_id 컬럼이 있나) ==='
SQL -c "
select column_name, data_type from information_schema.columns
where table_name = 'reviews' order by ordinal_position;"

echo ''
echo '=== 5. 혹시 진짜 예약이 섞여 있지는 않은가 (다시 확인) ==='
SQL -c "
select id, created_at::date as created, scheduled_at::date as sched,
       (scheduled_at < created_at) as impossible_date, is_paid, status::text
from bookings order by created_at;"
