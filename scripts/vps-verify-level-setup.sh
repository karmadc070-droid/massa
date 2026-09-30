#!/bin/sh
# 인증 2단계(신원 확인 / 자격 확인) 를 위한 DB 준비.
#  Z-12-1 Thanh hà 님 KYC 중복 정리 — 같은 서류를 4번 낸 것으로 기록돼 있다. 최신 1건만 남긴다.
#  Z-12-2 자격 확인 컬럼 추가.
#
# is_verified 는 '신원 확인(신분증)' 의미로 그대로 쓴다. 단계 값으로 바꾸면 기존 참조를 전부 고쳐야 한다.
set -e
SQL() { docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c "$1"; }

echo '=== Z-12-1. 중복 KYC 정리 — 먼저 백업 ==='
SQL "
drop table if exists provider_kyc_backup_20260930;
create table provider_kyc_backup_20260930 as select * from provider_kyc;
select count(*) as 백업행수 from provider_kyc_backup_20260930;
"

echo '--- 정리 전 ---'
SQL "select provider_id, count(*) as 행수 from provider_kyc group by 1 having count(*) > 1;"

SQL "
delete from provider_kyc k
using provider_kyc newer
where k.provider_id = newer.provider_id
  and (newer.created_at, newer.id) > (k.created_at, k.id);
"

echo '--- 정리 후 (중복 0 이어야 한다) ---'
SQL "select count(*) as 중복파트너수 from (select provider_id from provider_kyc group by 1 having count(*) > 1) t;"
SQL "select count(*) as 총KYC행수 from provider_kyc;"

echo ''
echo '=== Z-12-2. 자격 확인 컬럼 추가 ==='
SQL "
alter table providers add column if not exists credential_verified  boolean not null default false;
alter table providers add column if not exists credential_checked_at timestamptz;
"
SQL "
select column_name, data_type
from information_schema.columns
where table_name='providers' and column_name in ('is_verified','credential_verified','credential_checked_at')
order by column_name;
"

echo ''
echo '=== 현재 단계 분포 ==='
SQL "
select
  count(*)                                                   as 승인파트너,
  count(*) filter (where is_verified)                        as 신원확인,
  count(*) filter (where credential_verified)                as 자격확인,
  count(*) filter (where not is_verified)                    as 표시없음
from providers where application_status = 'approved';
"

echo '=== 서류를 실제로 낸 사람 (단계를 올릴 후보) ==='
SQL "
select p.display_name, p.application_status as 상태,
       (k.id_front_url is not null or k.id_back_url is not null) as 신분증,
       (k.cert_url is not null or k.business_license_url is not null) as 자격서류
from provider_kyc k join providers p on p.id = k.provider_id
where k.id_front_url is not null or k.id_back_url is not null
   or k.cert_url is not null or k.business_license_url is not null;
"
