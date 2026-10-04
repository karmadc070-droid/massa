#!/bin/sh
# '무명' 이 Thanh hà 와 같은 profile_id 에 붙어 있다. 같은 사람의 옛 신청인지 본다.
# 같은 사람이면 '1건만 남기고 삭제' 범위에 들어간다. 아니면 손대지 않는다.
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

echo '=== 무명 / Thanh hà 비교 ==='
SQL "
select p.display_name, p.application_status::text as 상태, p.is_active as 노출,
       coalesce(nullif(p.phone,''),'-') as 전화, p.created_at::timestamp(0) as 생성,
       coalesce(nullif(k.contact,''),'-')      as kyc연락처,
       coalesce(nullif(k.reg_type,''),'-')     as 등록형태,
       coalesce(nullif(k.id_front_url,''),'-') as 신분증앞
from providers p left join provider_kyc k on k.provider_id = p.id
where p.profile_id = 'adec3c30-746b-47db-bd8d-53ae164a142c'
order by p.created_at;
"

echo ''
echo '=== 무명에 딸린 것 ==='
SQL "
select (select count(*) from bookings where provider_id = p.id)          as 예약,
       (select count(*) from reviews  where provider_id = p.id)          as 후기,
       (select count(*) from provider_services where provider_id = p.id) as 서비스
from providers p where p.display_name = '무명';
"
