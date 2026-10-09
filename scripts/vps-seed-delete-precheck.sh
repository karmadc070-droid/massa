#!/bin/bash
# 시드 마사지사를 '지우기 전에' 무엇이 딸려 있는지 전부 센다. 읽기만 한다.
#
# 대상 - profile_id 가 없는 행(로그인 계정이 없는 = 내가 만든 가짜).
#        이 기준은 Z-33, Z-43 에서 쓴 것과 같다.
set -e
Q() { docker exec -i massa-db psql -U postgres -d postgres -c "$1" < /dev/null; }

echo '=== 1. 지울 대상 ==='
Q "select count(*) 대상수,
          count(*) filter (where is_active) 켜져있는것,
          min(created_at)::date 가장오래된, max(created_at)::date 가장최근
     from providers where profile_id is null;"

echo '=== 2. providers 를 가리키는 다른 테이블 (외래키) ==='
Q "select src.relname::text 테이블, a.attname::text 컬럼, c.confdeltype 삭제규칙
     from pg_constraint c
     join pg_class src on src.oid = c.conrelid
     join pg_attribute a on a.attrelid = c.conrelid and a.attnum = any(c.conkey)
    where c.contype = 'f' and c.confrelid = 'providers'::regclass
    order by 1;"
echo '  (삭제규칙 a=막음 c=같이삭제 n=NULL로 r=제한 d=기본값)'

echo '=== 3. 대상에 실제로 달려 있는 행 수 ==='
Q "with t as (select id from providers where profile_id is null)
   select 'bookings'          k, count(*) from bookings          where provider_id in (select id from t)
   union all select 'reviews',        count(*) from reviews          where provider_id in (select id from t)
   union all select 'provider_services', count(*) from provider_services where provider_id in (select id from t)
   union all select 'provider_price',  count(*) from provider_price   where provider_id in (select id from t)
   union all select 'provider_kyc',    count(*) from provider_kyc     where provider_id in (select id from t)
   union all select 'favorites',       count(*) from favorites        where provider_id in (select id from t)
   union all select 'store_providers', count(*) from store_providers  where provider_id in (select id from t)
   order by 2 desc;"

echo '=== 4. 혹시 로그인 계정이 생긴 사람이 섞였나 (0 이어야 한다) ==='
Q "select count(*) from providers where profile_id is null and owner_id is not null;"
