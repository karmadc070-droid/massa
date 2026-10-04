#!/bin/sh
# Thanh hà 중복 3건 삭제 (2단계 — 앞서 딸린 provider_kyc 3건 때문에 멈췄던 것).
#
# 지워도 되는 근거: KYC 4행이 전부 같은 파일 두 개를 가리킨다.
#   adec3c30-.../1787976173282_fukto.jpeg (앞) · .../1787976197505_llk3x.jpeg (뒤)
# 남길 1건(cf32fcbf)이 같은 파일을 이미 들고 있다. 서류는 하나도 잃지 않는다.
# 스토리지 파일 자체는 건드리지 않는다.
set -e
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

KEEP='cf32fcbf-200b-4f8b-a152-8b472a06a7ad'
DELS="'c6ac1c25-8475-4197-8036-b1fb336e8926','8c106c4e-5a11-4f34-9de6-323d1a5d9753','c07b0825-ba5e-4552-aaf1-35ef0dd75f6c'"

echo '=== 0. 안전 확인 — 남길 1건이 신분증을 들고 있나 (없으면 중단) ==='
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 <<SQLEOF
do \$\$
declare ok boolean;
begin
  select coalesce(id_front_url,'') <> '' and coalesce(id_back_url,'') <> ''
    into ok from provider_kyc where provider_id = '$KEEP';
  if not coalesce(ok,false) then
    raise exception '남길 1건에 신분증이 없다. 지우면 서류를 잃는다. 중단.';
  end if;
end \$\$;
SQLEOF
echo '  확인됨'

echo ''
echo '=== 1. KYC 백업 후 3건 삭제 ==='
SQL "create table if not exists provider_kyc_thanhha_backup_20261004 as
     select * from provider_kyc where provider_id in ($DELS);"
SQL "select count(*) as kyc백업 from provider_kyc_thanhha_backup_20261004;"
SQL "delete from provider_kyc where provider_id in ($DELS);"

echo ''
echo '=== 2. providers 3건 삭제 ==='
SQL "delete from providers where id in ($DELS);"

echo ''
echo '=== 3. 확인 ==='
SQL "select id, display_name, phone, application_status::text, is_active, is_verified
     from providers where display_name ilike '%thanh%';"
echo '  --- 전화번호 중복 (비어 있어야 한다) ---'
SQL "select phone, count(*) from providers
     where phone is not null and phone <> '' group by phone having count(*) > 1;"
echo '  --- 남은 KYC ---'
SQL "select provider_id, (coalesce(id_front_url,'') <> '') as 신분증앞있음
     from provider_kyc where provider_id = '$KEEP';"
