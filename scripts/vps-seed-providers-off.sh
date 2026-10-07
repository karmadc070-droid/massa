#!/bin/bash
# 시드 파트너를 목록에서 내린다.
#
# 무엇을 내리는가 - 로그인 계정도 없고 서류도 없는 행. 즉 실존하지 않는 프로필.
# 점검 결과 24명 중 22명이 여기 해당하고, 예약 0건 후기 0건이라 딸린 기록이 없다.
# 남는 사람 - Kun, Thanh ha (둘 다 로그인 계정 + 서류 제출 있음).
#
# 지우지 않고 is_active=false 로만 내린다. 되돌릴 수 있어야 하기 때문이다.
# 하드 삭제는 일주일 지켜본 뒤 따로 결정한다.
set -e
Q() { docker exec -i massa-db psql -U postgres -d postgres -c "$1" < /dev/null; }

TS=$(date +%Y%m%d-%H%M%S)
OUT=/root/massa-backup/seed-providers-$TS.csv
mkdir -p /root/massa-backup

echo '=== 1. 대상 확인 (내리기 전) ==='
Q "select count(*) 내릴_대상
     from providers p
    where p.profile_id is null
      and not exists (select 1 from provider_kyc k where k.provider_id=p.id)
      and p.is_active;"

echo ''
echo '=== 2. 안전 확인 - 예약이나 후기가 달린 대상이 있는가 ==='
Q "select count(*) 기록있는_대상
     from providers p
    where p.profile_id is null
      and not exists (select 1 from provider_kyc k where k.provider_id=p.id)
      and ( exists (select 1 from bookings b where b.provider_id=p.id)
         or exists (select 1 from reviews  r where r.provider_id=p.id) );"
echo '  >> 0 이 아니면 아래 UPDATE 가 스스로 멈춘다'

echo ''
echo "=== 3. 백업 ($OUT) ==="
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "\copy (
  select * from providers p
   where p.profile_id is null
     and not exists (select 1 from provider_kyc k where k.provider_id=p.id)
) to stdout with csv header" > "$OUT"
wc -l "$OUT" | sed 's/^/  /'

echo ''
echo '=== 4. 내리기 (한 트랜잭션, 안전장치 포함) ==='
docker exec -i massa-db psql -U postgres -d postgres <<'SQL'
begin;

-- 기록이 달린 행이 하나라도 있으면 전체 중단한다.
do $$
declare n int;
begin
  select count(*) into n from providers p
   where p.profile_id is null
     and not exists (select 1 from provider_kyc k where k.provider_id=p.id)
     and ( exists (select 1 from bookings b where b.provider_id=p.id)
        or exists (select 1 from reviews  r where r.provider_id=p.id) );
  if n > 0 then
    raise exception '기록이 달린 대상이 % 건 있다 - 중단한다', n;
  end if;
end $$;

update providers p
   set is_active = false
 where p.profile_id is null
   and not exists (select 1 from provider_kyc k where k.provider_id=p.id)
   and p.is_active;

commit;
SQL

echo ''
echo '=== 5. 결과 ==='
Q "select count(*) total,
          count(*) filter (where is_active) 화면에_보이는_수,
          count(*) filter (where is_verified) 인증마크
     from providers;"
Q "select left(display_name,20) name, is_active, is_verified,
          (profile_id is not null) has_login
     from providers where is_active order by created_at;"
