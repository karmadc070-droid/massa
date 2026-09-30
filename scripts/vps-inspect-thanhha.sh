#!/bin/sh
# Thanh hà 가 4번 나온다. KYC 중복이 아니라 파트너 레코드 자체가 4개였다.
# 어느 것이 살아 있는 것인지, 무엇이 다른지 본다. 읽기 전용 — 지우지 않는다.
set -e
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

echo '=== 같은 이름의 파트너 레코드 ==='
SQL "
select p.id, p.display_name, p.application_status as 상태, p.is_active as 노출,
       p.owner_id is not null as 계정있음, p.phone, p.base_district as 권역,
       p.created_at::date as 생성일
from providers p
where p.display_name ilike '%thanh%'
order by p.created_at;
"

echo '=== 각 레코드에 붙은 KYC ==='
SQL "
select k.provider_id, k.created_at::date as 제출일, k.contact,
       (k.id_front_url is not null) as 신분증앞, (k.bank_account is not null) as 계좌
from provider_kyc k
join providers p on p.id = k.provider_id
where p.display_name ilike '%thanh%'
order by k.created_at;
"

echo '=== 이 레코드들에 예약이 걸려 있나 (지우기 전에 반드시 확인) ==='
SQL "
select p.id, p.display_name, count(b.id) as 예약수
from providers p left join bookings b on b.provider_id = p.id
where p.display_name ilike '%thanh%'
group by 1,2;
"
