#!/bin/sh
# 시드 정리 범위를 정하기 전에 전체를 센다.
# 예약·후기가 시드에 붙어 있으면 지우는 순간 그것도 같이 사라진다. 먼저 알아야 한다.
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

echo '=== 1. 마사지사 25명 전수 ==='
SQL "
select p.display_name,
       p.application_status::text as 상태,
       p.is_active as 노출,
       p.is_verified as 신원,
       coalesce(nullif(p.phone,''),'-') as 전화,
       case when p.owner_id = 'adec3c30-746b-47db-bd8d-53ae164a142c' then 'Thanh하 계정'
            when p.owner_id is not null then 'owner 있음'
            when p.profile_id is not null then 'profile 있음'
            else '계정 없음' end as 계정,
       p.created_at::date as 생성,
       (select count(*) from bookings b where b.provider_id=p.id) as 예약,
       (select count(*) from reviews  r where r.provider_id=p.id) as 후기,
       (select count(*) from provider_kyc k where k.provider_id=p.id) as kyc
from providers p
order by p.created_at, p.display_name;
"

echo ''
echo '=== 2. 생성일로 묶어 보기 (시드는 한 날에 몰려 있다) ==='
SQL "select created_at::date as 생성일, count(*) from providers group by 1 order by 1;"

echo ''
echo '=== 3. 예약 8건은 누구에게 붙어 있나 ==='
SQL "
select p.display_name, b.status::text, b.scheduled_at::date, b.amount_vnd,
       (b.customer_id is not null) as 고객있음
from bookings b left join providers p on p.id = b.provider_id
order by b.created_at;
"

echo ''
echo '=== 4. 그 예약의 고객은 실제 사람인가 ==='
SQL "
select u.email, count(b.id) as 예약수
from bookings b join auth.users u on u.id = b.customer_id
group by 1 order by 2 desc;
"
