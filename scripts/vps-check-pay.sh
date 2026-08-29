#!/bin/sh
# 토스 결제 연동 전 사전 점검 — 읽기 전용
set -e
echo "=== payment_method enum 값 ==="
docker exec massa-db psql -U postgres -d postgres -t -A -c \
  "select e.enumlabel from pg_enum e join pg_type t on t.oid=e.enumtypid where t.typname='payment_method' order by e.enumsortorder;"

echo
echo "=== booking_status enum 값 ==="
docker exec massa-db psql -U postgres -d postgres -t -A -c \
  "select e.enumlabel from pg_enum e join pg_type t on t.oid=e.enumtypid where t.typname='booking_status' order by e.enumsortorder;"

echo
echo "=== 결제 관련 컬럼 현황 ==="
docker exec massa-db psql -U postgres -d postgres -t -A -F' | ' -c \
  "select column_name, data_type, is_nullable from information_schema.columns where table_name='bookings' and (column_name like '%pay%' or column_name like '%amount%' or column_name like '%discount%');"

echo
echo "=== bookings 건수 / 결제수단 분포 ==="
docker exec massa-db psql -U postgres -d postgres -t -A -F' | ' -c \
  "select payment_method::text, count(*) from bookings group by 1;"
docker exec massa-db psql -U postgres -d postgres -t -A -c "select count(*)||' 건' from bookings;"

echo
echo "=== Edge Function 예시 구조 (zalo-login) ==="
ls -la /root/massa/volumes/functions/zalo-login/
head -12 /root/massa/volumes/functions/zalo-login/index.ts 2>/dev/null

echo
echo "=== CHECK DONE ==="
