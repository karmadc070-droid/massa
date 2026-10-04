#!/bin/sh
# 중복 방지가 실제로 막는지 시험. 전부 롤백하므로 실제 데이터는 바뀌지 않는다.
# 가짜 profile id 는 auth.users FK 에 걸려서 못 쓴다 — 실존 계정으로 시험한다.
OWNER='adec3c30-746b-47db-bd8d-53ae164a142c'   # 이미 살아 있는 신청을 가진 실제 계정

echo '=== 시험 전 ==='
docker exec -i massa-db psql -U postgres -d postgres -c \
 "select count(*) as 전체 from providers;"

docker exec -i massa-db psql -U postgres -d postgres <<SQLEOF
\set ON_ERROR_STOP off
begin;

-- (가) 이미 살아 있는 신청이 있는 계정이 또 신청 → 막혀야 한다
insert into providers (display_name, owner_id, application_status)
values ('시험-중복', '$OWNER', 'pending');
select '가) 막히지 않았다 — 실패' as 결과;

rollback;
SQLEOF

echo ''
echo '=== (나) 반려 상태로는 들어가야 한다 (재신청 길을 막으면 안 된다) ==='
docker exec -i massa-db psql -U postgres -d postgres <<SQLEOF
\set ON_ERROR_STOP off
begin;
insert into providers (display_name, owner_id, application_status)
values ('시험-반려', '$OWNER', 'rejected');
select '나) 반려 상태 입력 통과 (정상)' as 결과;
rollback;
SQLEOF

echo ''
echo '=== 시험 후 — 숫자가 그대로여야 한다 ==='
docker exec -i massa-db psql -U postgres -d postgres -c \
 "select count(*) as 전체 from providers;"
docker exec -i massa-db psql -U postgres -d postgres -c \
 "select count(*) as 시험데이터남음 from providers where display_name like '시험-%';"
