#!/bin/sh
# 시드 마사지사 8명이 실제 고객 계정(Thanh hà, adec3c30)의 owner_id 로 묶여 있다.
# 그 사람이 파트너 콘솔에 들어가면 자기 것이 아닌 8명의 예약·매출을 보고 건드릴 수 있다.
#
# 시드 자체는 건드리지 않는다 (사용자가 그대로 두기로 결정).
# owner_id 만 떼면:
#   - 고객 화면은 그대로다. 목록 노출은 is_active 가 정하지 owner_id 가 정하지 않는다.
#   - 7/12 시드 15명은 이미 owner_id 가 비어 있고 멀쩡히 보인다. 같은 상태로 맞추는 것이다.
#   - Thanh hà 의 파트너 콘솔에서는 자기 것(Thanh hà 1건)만 남는다.
set -e
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }
OWNER='adec3c30-746b-47db-bd8d-53ae164a142c'

echo '=== 1. 떼어낼 대상 ==='
SQL "select id, display_name, application_status::text, is_active
     from providers where owner_id = '$OWNER' order by display_name;"

echo ''
echo '=== 2. 백업 ==='
SQL "create table if not exists providers_owner_detach_backup_20261004 as
     select id, display_name, owner_id, profile_id, now() as detached_at
     from providers where owner_id = '$OWNER';"
SQL "select count(*) as 백업 from providers_owner_detach_backup_20261004;"

echo ''
echo '=== 3. owner_id 만 분리 (다른 값은 손대지 않는다) ==='
SQL "update providers set owner_id = null where owner_id = '$OWNER';"

echo ''
echo '=== 4. 확인 ==='
echo '  --- Thanh hà 계정에 남은 것 (Thanh hà 본인 1건이어야 한다) ---'
SQL "select display_name, application_status::text,
            (owner_id is not null) as owner, (profile_id is not null) as prof
     from providers where owner_id = '$OWNER' or profile_id = '$OWNER';"
echo '  --- 노출 상태가 그대로인가 (8명 전부 살아 있어야 한다) ---'
SQL "select count(*) as 노출중 from providers where is_active = true;"
echo '  --- owner_id 중복이 사라졌나 (비어 있어야 한다) ---'
SQL "select owner_id, count(*) from providers
     where owner_id is not null and application_status in ('pending','approved')
     group by 1 having count(*) > 1;"
