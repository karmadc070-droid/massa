#!/bin/sh
# owner_id 하나에 살아 있는 마사지사가 8건이다. 이름으로 찾았을 때는 안 보였다.
# 지우기 전에 '같은 사람이 여러 번 신청한 것' 인지 '매장이 직원 여럿을 올린 것' 인지 봐야 한다.
# 둘은 완전히 다르다. 후자를 지우면 멀쩡한 등록을 지우는 것이다.
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

OWNER='adec3c30-746b-47db-bd8d-53ae164a142c'

echo '=== 이 계정이 누구인가 ==='
SQL "select id, email, full_name, role::text, created_at::date
     from profiles p join auth.users u on u.id = p.id where p.id = '$OWNER';" 2>/dev/null \
  || SQL "select id, role::text from profiles where id = '$OWNER';"

echo ''
echo '=== 이 계정에 달린 provider 전부 ==='
SQL "
select id, display_name, phone, tier::text, application_status::text as 상태,
       is_active, is_verified,
       (owner_id   is not null) as owner,
       (profile_id is not null) as prof,
       created_at
from providers where owner_id = '$OWNER' or profile_id = '$OWNER'
order by created_at;
"

echo ''
echo '=== 각 건에 딸린 것 (지워도 되는지 판단용) ==='
SQL "
select p.display_name, p.created_at::timestamp(0) as 등록,
       (select count(*) from bookings b where b.provider_id = p.id)          as 예약,
       (select count(*) from reviews r where r.provider_id = p.id)           as 후기,
       (select count(*) from provider_services s where s.provider_id = p.id) as 서비스,
       (select count(*) from provider_kyc k where k.provider_id = p.id)      as kyc
from providers p
where p.owner_id = '$OWNER' or p.profile_id = '$OWNER'
order by p.created_at;
"

echo ''
echo '=== 전체에서 owner_id 가 겹치는 다른 계정도 있나 ==='
SQL "
select owner_id, count(*) from providers
where owner_id is not null and application_status in ('pending','approved')
group by 1 having count(*) > 1;
"
