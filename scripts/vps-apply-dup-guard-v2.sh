#!/bin/sh
# 중복 방지 v2 적용 + 실제로 막히는지 시험한다.
# 적용됐다는 말만 믿지 않는다 — 넣어 보고 막히는지, 멀쩡한 건 통과하는지 둘 다 본다.
set -e
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

echo '=== 1. 적용 ==='
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < /root/dup_guard_v2.sql

echo ''
echo '=== 2. 트리거 확인 ==='
SQL "select tgname, pg_get_triggerdef(oid) from pg_trigger
     where tgrelid='public.providers'::regclass and not tgisinternal;"

echo ''
echo '=== 3. 시험 — 전부 롤백한다, 실제 데이터는 안 건드린다 ==='
docker exec -i massa-db psql -U postgres -d postgres <<'SQLEOF'
\set ON_ERROR_STOP off
begin;
-- 시험용 계정
insert into profiles (id, role) values ('11111111-1111-1111-1111-111111111111','customer')
  on conflict (id) do nothing;

-- (가) 첫 신청 — 통과해야 한다
insert into providers (id, display_name, owner_id, application_status)
values ('22222222-2222-2222-2222-222222222222','시험A','11111111-1111-1111-1111-111111111111','pending');
select '가) 첫 신청 통과' as 결과;

-- (나) 같은 계정으로 두 번째 — 막혀야 한다
insert into providers (id, display_name, owner_id, application_status)
values ('33333333-3333-3333-3333-333333333333','시험B','11111111-1111-1111-1111-111111111111','pending');
select '나) 두 번째가 통과했다 — 실패!' as 결과;

rollback;
SQLEOF

echo ''
echo '=== 4. 시험 — 기존 행 수정이 막히지 않는지 (시드 8명 보호) ==='
docker exec -i massa-db psql -U postgres -d postgres <<'SQLEOF'
\set ON_ERROR_STOP off
begin;
update providers set display_name = display_name
 where owner_id = 'adec3c30-746b-47db-bd8d-53ae164a142c';
select '다) 시드 8명 수정 통과 (' || count(*) || '건)' as 결과
  from providers where owner_id = 'adec3c30-746b-47db-bd8d-53ae164a142c';
rollback;
SQLEOF

echo ''
echo '=== 5. 실제 데이터가 그대로인지 ==='
SQL "select count(*) as 전체마사지사 from providers;"
SQL "select count(*) as 시험데이터남음 from providers
     where id in ('22222222-2222-2222-2222-222222222222','33333333-3333-3333-3333-333333333333');"
