#!/bin/bash
# 걷어내기 전에 '무엇이 있는지' 부터 본다. 읽기만 한다 - 아무것도 바꾸지 않는다.
set -e
Q() { docker exec -i massa-db psql -U postgres -d postgres -c "$1" < /dev/null; }

echo '=== 0. provider_kyc 컬럼 (앞서 status 를 가정했다가 틀렸다) ==='
Q "select column_name, data_type from information_schema.columns
    where table_name='provider_kyc' order by ordinal_position;"

echo '=== 0-2. providers 컬럼 ==='
Q "select column_name from information_schema.columns
    where table_name='providers' order by ordinal_position;"

echo '=== 1. 전체 현황 ==='
Q "select count(*) total,
          count(*) filter (where is_active) active,
          count(*) filter (where application_status='approved') approved,
          count(*) filter (where is_verified) verified,
          count(*) filter (where profile_id is null) no_login
     from providers;"

echo '=== 2. provider_kyc 에 행이 있는 provider 수 ==='
Q "select count(distinct provider_id) from provider_kyc;"

echo '=== 3. 한 줄씩 ==='
Q "select p.id, left(p.display_name,16) name,
          p.is_active act, p.is_verified ver, p.application_status st,
          (p.profile_id is not null) has_login,
          (select count(*) from provider_kyc k where k.provider_id=p.id) kyc,
          (select count(*) from bookings b where b.provider_id=p.id) bk,
          (select count(*) from reviews r where r.provider_id=p.id) rv,
          to_char(p.created_at,'MM-DD HH24:MI') created
     from providers p
    order by has_login desc, p.created_at;"
