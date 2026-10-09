#!/bin/bash
# 사이트에 내걸 수 있는 '진짜 숫자' 를 센다. 읽기만 한다.
# 부풀린 가입자 수 대신 쓸 재료를 찾는 것이 목적이다.
set -e
Q() { docker exec -i massa-db psql -U postgres -d postgres -t -c "$1" < /dev/null; }

echo '=== 테이블 목록 (쓸 만한 것 찾기) ==='
Q "select table_name from information_schema.tables
    where table_schema='public' order by table_name;" | tr -d ' ' | grep -v '^$' | tr '\n' ' '
echo; echo

echo '=== 활성 파트너 (개인 / 매장) ==='
Q "select coalesce(kind,'(없음)') kind, count(*) from providers where is_active group by 1;"

echo '=== 서비스(코스) 수 ==='
Q "select count(*) from services;" 2>/dev/null || echo '  services 테이블 없음'

echo '=== 구역 종류 ==='
Q "select count(distinct base_district) from providers where base_district is not null and base_district <> '';"

echo '=== 제휴 스파/매장 ==='
Q "select count(*) from stores;" 2>/dev/null || echo '  stores 테이블 없음'

echo '=== 앱 방문 기록 (실제 트래픽) ==='
Q "select count(*) total, count(distinct coalesce(visitor_id::text, id::text)) from app_visit;" 2>/dev/null \
  || echo '  app_visit 집계 실패'
