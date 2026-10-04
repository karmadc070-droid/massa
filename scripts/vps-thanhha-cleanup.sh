#!/bin/sh
# Thanh hà 중복 4건 중 승인된 1건만 남기고 3건 삭제.
# 삭제 전에 (1) 백업 (2) 딸린 데이터 확인. 딸린 게 있으면 지우지 않고 멈춘다.
set -e
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

KEEP='cf32fcbf-200b-4f8b-a152-8b472a06a7ad'   # approved · is_active
DEL1='c6ac1c25-8475-4197-8036-b1fb336e8926'
DEL2='8c106c4e-5a11-4f34-9de6-323d1a5d9753'
DEL3='c07b0825-ba5e-4552-aaf1-35ef0dd75f6c'
DELS="'$DEL1','$DEL2','$DEL3'"

echo '=== 1. 남길 것 / 지울 것 ==='
SQL "select id, application_status::text, is_active,
            case when id='$KEEP' then '남김' else '삭제' end as 처리
     from providers where display_name ilike '%thanh%' order by created_at;"

echo ''
echo '=== 2. 지울 3건에 딸린 데이터 (0 이어야 안전하다) ==='
SQL "
select 'bookings' t, count(*) from bookings where provider_id in ($DELS)
union all select 'reviews', count(*) from reviews where provider_id in ($DELS)
union all select 'provider_services', count(*) from provider_services where provider_id in ($DELS)
union all select 'provider_kyc', count(*) from provider_kyc where provider_id in ($DELS)
union all select 'provider_price', count(*) from provider_price where provider_id in ($DELS)
union all select 'favorites', count(*) from favorites where provider_id in ($DELS);
"

echo ''
echo '=== 3. 백업 (되돌릴 수 있게) ==='
SQL "create table if not exists providers_thanhha_backup_20261004 as
     select * from providers where id in ($DELS);"
SQL "select count(*) as 백업행수 from providers_thanhha_backup_20261004;"

echo ''
echo '=== 4. 딸린 데이터가 있으면 여기서 멈춘다 ==='
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 <<SQLEOF
do \$\$
declare n int;
begin
  select (select count(*) from bookings where provider_id in ($DELS))
       + (select count(*) from reviews  where provider_id in ($DELS))
       + (select count(*) from provider_services where provider_id in ($DELS))
       + (select count(*) from provider_kyc where provider_id in ($DELS))
    into n;
  if n > 0 then
    raise exception '딸린 데이터가 % 건 있다. 삭제하지 않는다.', n;
  end if;
end \$\$;
SQLEOF

echo ''
echo '=== 5. 삭제 ==='
SQL "delete from providers where id in ($DELS);"

echo ''
echo '=== 6. 확인 — 1건만 남아야 한다 ==='
SQL "select id, display_name, phone, application_status::text, is_active
     from providers where display_name ilike '%thanh%';"
SQL "select phone, count(*) from providers
     where phone is not null and phone <> '' group by phone having count(*) > 1;"
echo '(위 중복 목록이 비어 있어야 한다)'
