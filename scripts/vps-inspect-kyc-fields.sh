#!/bin/sh
# 지금 시스템이 실제로 받을 수 있는 서류가 무엇인지, 그리고 실제로 받은 게 무엇인지 본다.
# 읽기 전용. 인증 절차를 새로 정하기 전에 '할 수 있는 것' 부터 확인한다.
set -e
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

echo '=== 제출된 KYC 레코드 (파일이 실제로 있는지만 본다. 내용은 보지 않는다) ==='
SQL "
select p.display_name,
       k.reg_type                                as 등록유형,
       (k.id_front_url        is not null)       as 신분증앞,
       (k.id_back_url         is not null)       as 신분증뒤,
       (k.business_license_url is not null)      as 사업자등록,
       (k.cert_url            is not null)       as 자격증,
       (k.bank_account        is not null)       as 정산계좌,
       k.created_at::date                        as 제출일
from provider_kyc k
join providers p on p.id = k.provider_id;
"

echo '=== 위생 인증 상태 ==='
SQL "select count(*) filter (where hygiene_certified) as 위생인증됨,
            count(*) filter (where hygiene_checked_at is not null) as 확인기록있음,
            count(*) as 승인파트너
     from providers where application_status = 'approved';"
