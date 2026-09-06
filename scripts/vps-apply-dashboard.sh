#!/bin/sh
# 대시보드 스키마를 적용하고 권한이 실제로 막히는지까지 확인한다.
set -e
TMP=$(mktemp -d)
curl -s --location codeload.github.com/karmadc070-droid/massa/tar.gz/refs/heads/main -o "$TMP/m.tgz"
tar -xzf "$TMP/m.tgz" -C "$TMP"
SQL="$TMP/massa-main/scripts/dashboard_schema.sql"
test -s "$SQL" || { echo "스키마 파일을 못 받았다 — 중단"; exit 1; }

echo "=== 1. 스키마 적용 ==="
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < "$SQL"
rm -rf "$TMP"

echo
echo "=== 2. 권한 검사 (auth.uid() 를 흉내내 호출한다) ==="
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
\set ON_ERROR_STOP off
select id as admin_id from public.profiles where role='admin' limit 1 \gset
select id as cust_id  from public.profiles where role='customer' limit 1 \gset

\echo '--- 관리자로 호출 (성공해야 한다) ---'
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'admin_id')::text, true);
  select jsonb_pretty(public.admin_dashboard('day', 7));
commit;

\echo '--- 일반 고객으로 호출 (거부돼야 한다) ---'
begin;
  select set_config('request.jwt.claims', json_build_object('sub', :'cust_id')::text, true);
  select public.admin_dashboard('day', 7);
rollback;

\echo '--- 비로그인으로 app_visit 직접 읽기 (0행이어야 한다) ---'
begin;
  set local role anon;
  select count(*) as anon_이_읽은_행수 from public.app_visit;
rollback;

\echo '--- track_visit 기록 시험 ---'
select public.track_visit('selftest-'||to_char(now(),'YYYYMMDD'), 'test', 'ko');
select visit_date, device_id, platform, is_member from public.app_visit order by created_at desc limit 3;
PSQL

echo
echo "=== 3. PostgREST 스키마 재적재 ==="
docker exec massa-db psql -U postgres -d postgres -q -c "notify pgrst, 'reload schema';"
echo "=== DASHBOARD DONE ==="
