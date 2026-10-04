#!/bin/sh
# 지울 3건에 provider_kyc 가 붙어 있다. 안에 실제 서류가 있는지 본다.
# 빈 껍데기면 같이 지우고, 서류가 있으면 남길 1건으로 옮겨야 한다. 서류를 버리면 안 된다.
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

echo '=== provider_kyc 컬럼 ==='
SQL "select column_name from information_schema.columns
     where table_schema='public' and table_name='provider_kyc' order by ordinal_position;"

echo ''
echo '=== Thanh ha 4건의 KYC 내용 (파일이 들어 있나) ==='
SQL "
select k.provider_id,
       p.application_status::text as 상태,
       coalesce(nullif(k.id_front_url,''),'-')          as 신분증앞,
       coalesce(nullif(k.id_back_url,''),'-')           as 신분증뒤,
       coalesce(nullif(k.cert_url,''),'-')              as 자격증,
       coalesce(nullif(k.business_license_url,''),'-')  as 사업자
from provider_kyc k join providers p on p.id = k.provider_id
where p.display_name ilike '%thanh%'
order by p.created_at;
"

echo ''
echo '=== 파일이 하나라도 있는 행이 몇 개인가 ==='
SQL "
select count(*) as 서류있는행
from provider_kyc k join providers p on p.id = k.provider_id
where p.display_name ilike '%thanh%'
  and (coalesce(k.id_front_url,'') <> '' or coalesce(k.id_back_url,'') <> ''
    or coalesce(k.cert_url,'') <> ''     or coalesce(k.business_license_url,'') <> '');
"
