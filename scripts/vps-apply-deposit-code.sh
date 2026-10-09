#!/bin/bash
# 입금코드 자동 발급을 올리고, 실제 가입 경로로 시험한다. 시험은 롤백하는 트랜잭션 안에서 한다.
set -e
P() { docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 "$@"; }

echo '=== 0. 적용 전 상태 ==='
P -c "select display_name 이름, coalesce(deposit_code,'(없음)') 코드 from providers order by created_at;" < /dev/null

echo ''
echo '=== 1. 올리기 ==='
P < /tmp/dc.sql

echo ''
echo '=== 2. 적용 후 ==='
P -c "select display_name 이름, deposit_code 코드 from providers order by created_at;" < /dev/null
P -c "select count(*) 코드없는사람 from providers where deposit_code is null;" < /dev/null

echo ''
echo '=== 3. 신규 가입 시험 (일반 회원 권한, 롤백) ==='
echo '    가드가 deposit_code 를 막는데도 발급이 되는지 본다'
CUST=$(docker exec -i massa-db psql -U postgres -d postgres -t -A < /dev/null \
       -c "select p.id from profiles p where p.role='customer'
             and not exists (select 1 from providers pr
                              where pr.profile_id=p.id or pr.owner_id=p.id) limit 1;")
echo "    시험 계정 $CUST"
docker exec -i massa-db psql -U postgres -d postgres <<SQL
begin;
set local role authenticated;
select set_config('request.jwt.claims',
       json_build_object('sub','$CUST','role','authenticated')::text, true);
-- 앱이 실제로 보내는 행 그대로다 (index.html 2923행). 가드가 pending 외의 신청을 거부한다.
insert into providers (profile_id, kind, display_name, specialties, is_active, application_status, rating, review_count)
values ('$CUST', 'masseur', '코드시험', array['aroma'], false, 'pending', 0, 0);
select display_name 이름, deposit_code 발급된코드, application_status 상태
  from providers where profile_id = '$CUST';
rollback;
SQL

echo ''
echo '=== 4. 트리거 순서 (guard 가 먼저, zz_code 가 나중이어야 한다) ==='
P -c "select tgname from pg_trigger where tgrelid='providers'::regclass and not tgisinternal order by tgname;" < /dev/null
