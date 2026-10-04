#!/bin/sh
# 마무리: '무명' 빈 껍데기 삭제 → 부분 유니크 인덱스 두 개.
#
# '무명' 은 Thanh hà 와 같은 profile_id 의 버려진 신청이다.
#   이름·전화·신분증 전부 없음, 예약·후기·서비스 0건, pending, 노출 꺼짐.
#   '1건만 남기고 삭제' 범위에 들어간다.
#
# 이게 끝나야 유니크 인덱스를 걸 수 있다. 인덱스가 마지막 방어선이다 —
# 트리거만으로는 같은 순간에 들어온 두 요청이 둘 다 통과한다.
set -e
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

echo '=== 1. 지울 대상 확인 (빈 껍데기가 맞는지 다시 본다) ==='
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 <<'SQLEOF'
do $$
declare r record;
begin
  select p.id, p.display_name, p.phone, p.is_active,
         (select count(*) from bookings where provider_id=p.id) b,
         (select count(*) from reviews  where provider_id=p.id) rv,
         (select count(*) from provider_services where provider_id=p.id) sv
    into r
  from providers p where p.display_name = '무명';

  if r.id is null then raise exception '무명 을 못 찾았다'; end if;
  if r.b > 0 or r.rv > 0 or r.sv > 0 then
    raise exception '무명에 딸린 데이터가 있다 (예약 % 후기 % 서비스 %). 중단.', r.b, r.rv, r.sv;
  end if;
  if r.is_active then raise exception '무명이 노출 중이다. 중단.'; end if;
  raise notice '빈 껍데기 확인됨 — 진행';
end $$;
SQLEOF

echo ''
echo '=== 2. 백업 후 삭제 ==='
SQL "create table if not exists providers_muname_backup_20261004 as
     select * from providers where display_name = '무명';"
SQL "create table if not exists provider_kyc_muname_backup_20261004 as
     select k.* from provider_kyc k join providers p on p.id = k.provider_id
     where p.display_name = '무명';"
SQL "delete from provider_kyc where provider_id in (select id from providers where display_name = '무명');"
SQL "delete from providers where display_name = '무명';"

echo ''
echo '=== 3. 이제 중복이 없는지 ==='
SQL "
select 'owner_id' as 기준, count(*) from (
  select owner_id from providers
  where owner_id is not null and application_status in ('pending','approved')
  group by 1 having count(*) > 1) x
union all
select 'profile_id', count(*) from (
  select profile_id from providers
  where profile_id is not null and application_status in ('pending','approved')
  group by 1 having count(*) > 1) y;
"
echo '(둘 다 0 이어야 한다)'

echo ''
echo '=== 4. 유니크 인덱스 — 동시 요청까지 막는 마지막 방어선 ==='
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 <<'SQLEOF'
create unique index if not exists providers_one_live_per_owner
  on public.providers (owner_id)
  where owner_id is not null and application_status in ('pending','approved');

create unique index if not exists providers_one_live_per_profile
  on public.providers (profile_id)
  where profile_id is not null and application_status in ('pending','approved');
SQLEOF

echo ''
echo '=== 5. 확인 ==='
SQL "select indexname from pg_indexes
     where tablename='providers' and indexname like 'providers_one_live%';"
SQL "select count(*) as 전체마사지사 from providers;"
SQL "select count(*) as 노출중 from providers where is_active = true;"
