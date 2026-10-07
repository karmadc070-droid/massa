#!/bin/bash
# 걷어내기 전에 '무엇이 있는지' 부터 본다. 읽기만 한다 - 아무것도 바꾸지 않는다.
#
# 알아야 할 것 -
#  1) providers 가 몇 명이고 어떤 상태인가
#  2) 서류(provider_kyc)가 있는 사람은 누구인가
#  3) 어느 것이 시드(가짜)이고 어느 것이 실제 가입자인가 - 로그인 계정 유무로 가른다
#  4) 예약/후기 같은 실제 기록이 달려 있는 행이 있는가 (있으면 지우면 안 된다)
set -e
Q() { docker exec -i massa-db psql -U postgres -d postgres -c "$1" < /dev/null; }

echo '=== 1. 전체 현황 ==='
Q "select count(*) total,
          count(*) filter (where is_active) active,
          count(*) filter (where application_status='approved') approved,
          count(*) filter (where is_verified) verified,
          count(*) filter (where profile_id is null) no_login
     from providers;"

echo '=== 2. 서류 보유 현황 (provider_kyc) ==='
Q "select coalesce(k.status,'(서류 없음)') kyc, count(*)
     from providers p
     left join provider_kyc k on k.provider_id = p.id
    group by 1 order by 2 desc;"

echo '=== 3. 한 줄씩 - 누가 시드이고 누가 실제인가 ==='
Q "select p.id, left(p.display_name,16) name,
          p.is_active act, p.is_verified ver, p.application_status st,
          (p.profile_id is not null) has_login,
          coalesce(k.status,'-') kyc,
          (select count(*) from bookings b where b.provider_id=p.id) bk,
          (select count(*) from reviews r where r.provider_id=p.id) rv,
          to_char(p.created_at,'MM-DD HH24:MI') created
     from providers p
     left join provider_kyc k on k.provider_id=p.id
    order by has_login desc, p.created_at;"

echo '=== 4. 걷어낼 후보 (로그인 계정 없음 + 서류 없음) ==='
Q "select count(*) 걷어낼_후보
     from providers p
     left join provider_kyc k on k.provider_id=p.id
    where p.profile_id is null
      and (k.status is null or k.status <> 'approved');"

echo '=== 5. 그 후보에 실제 기록이 달려 있는가 (있으면 지우면 안 된다) ==='
Q "select count(*) 예약있는_후보
     from providers p
     left join provider_kyc k on k.provider_id=p.id
    where p.profile_id is null
      and (k.status is null or k.status <> 'approved')
      and exists (select 1 from bookings b where b.provider_id=p.id);"
