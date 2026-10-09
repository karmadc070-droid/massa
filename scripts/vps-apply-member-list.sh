#!/bin/bash
# admin_member_list 함수를 올리고, 관리자/비관리자 양쪽에서 실제로 시험한다.
# 시험은 롤백하는 트랜잭션 안에서 한다.
set -e
SHA="$1"
[ -z "$SHA" ] && { echo '커밋 SHA 를 인자로 주세요'; exit 1; }

echo '=== 1. 함수 올리기 ==='
curl -fsSL "https://raw.githubusercontent.com/karmadc070-droid/massa/$SHA/scripts/sql-admin-member-list.sql" -o /tmp/ml.sql
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < /tmp/ml.sql

echo ''
echo '=== 2. 관리자로 호출 (되어야 한다) ==='
ADMIN=$(docker exec -i massa-db psql -U postgres -d postgres -t -A < /dev/null \
        -c "select id from profiles where role='admin' limit 1;")
echo "  관리자 계정 $ADMIN"
docker exec -i massa-db psql -U postgres -d postgres <<SQL
begin;
set local role authenticated;
select set_config('request.jwt.claims',
       json_build_object('sub','$ADMIN','role','authenticated')::text, true);
select count(*) as 받아온_행수 from admin_member_list();
select full_name, email, phone, role, bookings
  from admin_member_list(null, null, 5, 0);
rollback;
SQL

echo ''
echo '=== 3. 일반 회원으로 호출 (막혀야 한다) ==='
CUST=$(docker exec -i massa-db psql -U postgres -d postgres -t -A < /dev/null \
       -c "select id from profiles where role='customer' limit 1;")
echo "  일반 계정 $CUST"
docker exec -i massa-db psql -U postgres -d postgres <<SQL || echo '  >> 위 오류가 정상이다 (막힘)'
begin;
set local role authenticated;
select set_config('request.jwt.claims',
       json_build_object('sub','$CUST','role','authenticated')::text, true);
select count(*) from admin_member_list();
rollback;
SQL

echo ''
echo '=== 4. 비로그인(anon)으로 호출 (막혀야 한다) ==='
docker exec -i massa-db psql -U postgres -d postgres <<'SQL' || echo '  >> 위 오류가 정상이다 (막힘)'
begin;
set local role anon;
select count(*) from admin_member_list();
rollback;
SQL
