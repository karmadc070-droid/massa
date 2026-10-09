#!/bin/bash
# 사이트에 내걸 수 있는 '진짜 숫자' 를 센다. 읽기만 한다.
# 부풀린 가입자 수 대신 쓸 재료를 찾는 것이 목적이다.
set -e
Q() { docker exec -i massa-db psql -U postgres -d postgres -t -c "$1" < /dev/null; }

echo '=== 활성 파트너 (종류별) ==='
Q "select kind::text, count(*) from providers where is_active group by 1;"

echo '=== 서비스(코스) ==='
Q "select count(*) from services;"
Q "select count(distinct category::text) from services;"

echo '=== 제휴 스파/매장 ==='
Q "select count(*) from stores;"
Q "select count(*) from stores where is_active;" 2>/dev/null || true

echo '=== 가입 계정 수 (profiles) ==='
Q "select count(*) from profiles;"

echo '=== 앱 방문 기록 ==='
Q "select count(*) from app_visit;"

echo '=== 쿠폰 ==='
Q "select count(*) from coupons;"

echo '=== services 컬럼 (카테고리 이름 확인용) ==='
Q "select column_name from information_schema.columns where table_name='services' order by ordinal_position;" | tr -d ' ' | grep -v '^$' | tr '\n' ' '
echo
echo '=== stores 컬럼 ==='
Q "select column_name from information_schema.columns where table_name='stores' order by ordinal_position;" | tr -d ' ' | grep -v '^$' | tr '\n' ' '
echo
