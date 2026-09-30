#!/bin/sh
# 인증 마크가 실제 서류에 근거하는지 다시 본다.
# 앞서 'KYC 레코드가 있으면 인증' 으로 처리했는데, 레코드는 있어도 파일이 하나도 없는 경우가 있었다.
# 서류 = 신분증 앞/뒤 중 하나라도 있는 것으로 본다.
set -e
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

echo '=== 인증 마크가 붙은 파트너와 그 근거 ==='
SQL "
select p.display_name, p.application_status as 상태, p.is_verified as 인증마크,
       (k.provider_id is not null)                                  as KYC행있음,
       (k.id_front_url is not null or k.id_back_url is not null)     as 신분증파일있음
from providers p
left join provider_kyc k on k.provider_id = p.id
where p.is_verified;
"

echo '=== 서류를 실제로 낸 사람은 누구인가 (상태 무관) ==='
SQL "
select p.display_name, p.application_status as 상태, p.is_verified as 인증마크, count(*) as KYC행수
from provider_kyc k
join providers p on p.id = k.provider_id
where k.id_front_url is not null or k.id_back_url is not null
group by 1,2,3;
"
