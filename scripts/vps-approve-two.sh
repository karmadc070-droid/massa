#!/bin/bash
# 심사 대기 중인 테라피스트 2명(Thao, Hong Tra)을 승인한다.
#
# 안전장치 - 신분증 앞뒤가 둘 다 올라와 있는 사람만 승인한다.
# 하나라도 없으면 그 행은 건드리지 않는다.
#
# is_verified(인증 마크)는 건드리지 않는다. 그건 사람이 서류를 눈으로 본 뒤에만 켠다.
# 예전에 'approved 면 자동으로 마크' 로 돼 있어서 서류 없는 파트너 21명에게
# 인증 마크가 붙었던 적이 있다. 같은 일을 반복하지 않는다.
set -e

echo '=== 승인 전 ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select display_name, application_status, is_verified from providers
 where application_status='pending' order by created_at;"

echo ''
echo '=== 승인 (서류 갖춘 사람만) ==='
docker exec -i massa-db psql -U postgres -d postgres <<'SQL'
begin;
update providers p
   set application_status = 'approved',
       reviewed_at        = now()
 where p.application_status = 'pending'
   and exists (
     select 1 from provider_kyc k
      where k.provider_id = p.id
        and k.id_front_url is not null
        and k.id_back_url  is not null);
commit;
SQL

echo ''
echo '=== 승인 후 ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select display_name, application_status, is_verified, is_active,
       to_char(reviewed_at,'MM-DD HH24:MI') 승인시각
  from providers
 where profile_id is not null
 order by created_at;"

echo ''
echo '=== 고객 목록에 보이는 파트너 수 ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select count(*) from providers where is_active and application_status='approved';"
