#!/bin/sh
# 토스 결제 연동 전 사전 점검 — 컨테이너·함수·DB 스키마 상태를 읽기만 한다
set -e

echo "=== massa 컨테이너 ==="
docker ps -a --filter name=massa --format '{{.Names}} :: {{.Status}}'

echo
echo "=== Edge Functions 목록 ==="
ls -1 /root/massa/volumes/functions

echo
echo "=== functions 컨테이너 로그 (마지막 5줄) ==="
F=$(docker ps --format '{{.Names}}' | grep massa | grep -i function | head -1)
echo "container: ${F:-없음}"
[ -n "$F" ] && docker logs --tail 5 "$F" 2>&1

echo
echo "=== bookings 컬럼 ==="
docker exec massa-db psql -U postgres -d postgres -t -A -F' | ' -c \
  "select column_name, data_type from information_schema.columns where table_name='bookings' order by ordinal_position;"

echo
echo "=== payments 관련 테이블 존재 여부 ==="
docker exec massa-db psql -U postgres -d postgres -t -A -c \
  "select table_name from information_schema.tables where table_schema='public' and (table_name like '%pay%' or table_name like '%settle%' or table_name like '%order%');"

echo
echo "=== bookings 의 payment_method 값 분포 ==="
docker exec massa-db psql -U postgres -d postgres -t -A -F' | ' -c \
  "select coalesce(payment_method,'(null)'), count(*) from bookings group by 1 order by 2 desc;"

echo
echo "=== .env 에 토스 관련 값이 있는지 (값은 가림) ==="
grep -i "toss\|payment" /root/massa/.env | sed 's/=.*/=***/' || echo "(없음)"

echo
echo "=== CHECK PAY DONE ==="
