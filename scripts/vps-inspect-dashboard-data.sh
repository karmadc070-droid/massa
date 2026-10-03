#!/bin/sh
# 대시보드 3종을 만들기 전에 '무엇을 보여줄 수 있는가' 를 먼저 본다.
# 없는 데이터로 화면을 그리면 빈 칸만 나온다. 스키마부터 읽고 설계한다.
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

echo '=== 1. 테이블 목록과 행 수 ==='
SQL "
select c.relname as 테이블, c.reltuples::bigint as 대략행수
from pg_class c join pg_namespace n on n.oid=c.relnamespace
where n.nspname='public' and c.relkind='r'
order by 1;
"

echo ''
echo '=== 2. bookings 컬럼 (고객·마사지사 대시보드의 뼈대) ==='
SQL "
select column_name, data_type
from information_schema.columns
where table_schema='public' and table_name='bookings' order by ordinal_position;
"

echo ''
echo '=== 3. 예약 상태값이 실제로 어떤 것들인가 ==='
SQL "select status, count(*) from bookings group by 1 order by 2 desc;"

echo ''
echo '=== 4. 이미 있는 RPC 함수 (다시 만들지 않기 위해) ==='
SQL "
select p.proname as 함수, pg_get_function_arguments(p.oid) as 인자
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public' order by 1;
"

echo ''
echo '=== 5. 실제 데이터가 얼마나 있나 ==='
SQL "
select
  (select count(*) from bookings)  as 예약,
  (select count(*) from providers) as 마사지사,
  (select count(*) from profiles)  as 회원,
  (select count(*) from reviews)   as 후기;
"
