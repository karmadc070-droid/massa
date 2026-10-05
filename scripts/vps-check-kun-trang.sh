#!/bin/sh
# Kun, Trang 두 명에게 별점·인증마크를 붙여도 되는지 판단할 근거를 본다.
# 판단 기준은 두 가지뿐이다 — 서류(kyc)가 실제로 있나, 받은 후기가 실제로 있나.
# PowerShell 이 한글을 깨뜨리므로 SQL 안에는 ASCII 만 쓴다 (기록된 교훈).
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

echo '=== 1. providers matching kun / trang ==='
SQL "
select p.display_name, p.application_status::text as status,
       p.is_active as visible, p.is_verified as verified_mark,
       (select count(*) from provider_kyc k where k.provider_id=p.id) as docs,
       (select count(*) from bookings b where b.provider_id=p.id) as bookings,
       (select count(*) from bookings b where b.provider_id=p.id and b.status='completed') as done,
       (select count(*) from reviews r where r.provider_id=p.id) as reviews
from providers p
where p.display_name ilike '%kun%' or p.display_name ilike '%trang%'
order by p.display_name;
"

echo ''
echo '=== 2. provider_kyc columns ==='
SQL "select column_name, data_type from information_schema.columns
     where table_name='provider_kyc' order by ordinal_position;"

echo ''
echo '=== 3. Kun KYC rows (all columns) ==='
SQL "select k.* from provider_kyc k join providers p on p.id=k.provider_id
     where p.display_name ilike '%kun%';"
