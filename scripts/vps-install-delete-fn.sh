#!/bin/sh
# 계정 삭제 RPC 함수를 massa-db에 설치하고 blocks/reports 테이블 존재를 확인한다
set -e

DB=$(docker ps --format '{{.Names}}' | grep massa | grep -i db | head -1)
echo "=== DB container: $DB ==="

curl -s --location raw.githubusercontent.com/karmadc070-droid/massa/main/scripts/delete_account_fn.sql -o /tmp/fn.sql
docker exec -i "$DB" psql -U postgres -d postgres -v ON_ERROR_STOP=1 < /tmp/fn.sql

docker exec -i "$DB" psql -U postgres -d postgres <<'SQL'
\pset pager off
SELECT proname, pg_get_function_identity_arguments(oid) AS args
  FROM pg_proc WHERE proname = 'delete_my_account';
SELECT table_name FROM information_schema.tables
 WHERE table_schema = 'public' AND table_name IN ('blocks','reports','messages')
 ORDER BY 1;
SQL

echo "=== INSTALL DONE ==="
