#!/bin/bash
# 유입 역할 구분을 올리고, 실제 호출 경로로 시험한다. 시험은 롤백하는 트랜잭션 안에서 한다.
set -e
P() { docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 "$@"; }

echo '=== 1. 올리기 ==='
P < /tmp/vr.sql

echo ''
echo '=== 2. 지금까지 쌓인 기록 (과거는 전부 role 없음이 정상) ==='
P -c "select coalesce(role,'(로그인 전)') 역할, count(*) 건수 from app_visit group by 1 order by 2 desc;" < /dev/null

echo ''
echo '=== 3. track_visit 시험 — 손님으로 호출 (롤백) ==='
CUST=$(docker exec -i massa-db psql -U postgres -d postgres -t -A < /dev/null \
       -c "select p.id from profiles p where p.role='customer'
             and not exists (select 1 from providers pr
                              where pr.profile_id=p.id or pr.owner_id=p.id) limit 1;")
PROV=$(docker exec -i massa-db psql -U postgres -d postgres -t -A < /dev/null \
       -c "select profile_id from providers where profile_id is not null limit 1;")
echo "    손님 $CUST / 마사지사 $PROV"
docker exec -i massa-db psql -U postgres -d postgres 2>&1 <<SQL
begin;
set local role authenticated;

-- 비회원이 먼저 한 번 연다
select set_config('request.jwt.claims', null, true);
set local role anon;
select track_visit('dev-test-1', 'web', 'ko');

-- 같은 기기로 로그인한 뒤 다시 연다. 역할이 올라가야 한다 (do nothing 이면 안 올라간다)
set local role authenticated;
select set_config('request.jwt.claims',
       json_build_object('sub','$CUST','role','authenticated')::text, true);
select track_visit('dev-test-1', 'web', 'ko');

select set_config('request.jwt.claims',
       json_build_object('sub','$PROV','role','authenticated')::text, true);
select track_visit('dev-test-2', 'ios', 'vi');

set local role postgres;
select device_id 기기, coalesce(role,'(로그인 전)') 역할, is_member 로그인
  from app_visit where device_id like 'dev-test-%' order by device_id;
rollback;
SQL

echo ''
echo '=== 4. 대시보드가 새 칸을 돌려주는지 ==='
ADMIN=$(docker exec -i massa-db psql -U postgres -d postgres -t -A < /dev/null \
        -c "select id from profiles where role='admin' limit 1;")
docker exec -i massa-db psql -U postgres -d postgres 2>&1 <<SQL
begin;
set local role authenticated;
select set_config('request.jwt.claims',
       json_build_object('sub','$ADMIN','role','authenticated')::text, true);
select jsonb_pretty(admin_dashboard('day', 3) -> 'today') as 오늘;
select jsonb_pretty(admin_dashboard('day', 3) -> 'sum')   as 기간합;
rollback;
SQL
