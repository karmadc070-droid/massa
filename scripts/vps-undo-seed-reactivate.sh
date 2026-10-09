#!/bin/bash
# 긴급 복구 - 앞 스크립트가 시드 파트너 22명을 도로 켜버렸다.
#
# 무엇이 틀렸나 - UPDATE 조건을 'approved 이고 is_active=false' 로만 잡았다.
# 시드 22명도 전부 approved 상태로 비활성화돼 있었기 때문에 같이 걸려들었다.
# 'profile_id is not null' (실제 로그인 계정이 있는 사람) 조건을 빼먹은 것이 원인이다.
#
# 올바른 상태 - 로그인 계정이 있는 5명만 켜져 있어야 한다.
#   Kun, Thanh ha, Thao, Hong Tra, Tran Thanh
set -e

echo '=== 1. 지금 켜져 있는 사람 ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select count(*) filter (where profile_id is not null) 실제계정,
       count(*) filter (where profile_id is null)     시드
  from providers where is_active and application_status='approved';"

echo ''
echo '=== 2. 시드만 다시 내린다 (로그인 계정 없는 행) ==='
docker exec -i massa-db psql -U postgres -d postgres <<'SQL'
begin;
update providers
   set is_active = false
 where profile_id is null
   and is_active = true;
commit;
SQL

echo ''
echo '=== 3. 결과 - 고객 목록에 보이는 사람 전부 ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select display_name, is_verified, coalesce(service_area,'-') 구역
  from providers
 where is_active and application_status='approved'
 order by created_at;"

echo '=== 4. 숫자 확인 (5명이어야 한다) ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select count(*) 노출중 from providers where is_active and application_status='approved';"

echo ''
echo '=== 5. 시드가 다시 꺼졌는지 ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select count(*) 시드_켜진것 from providers where profile_id is null and is_active;"
