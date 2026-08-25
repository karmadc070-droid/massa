#!/bin/sh
# massa DB 컨테이너를 찾아 auth.users를 참조하는 외래키 구조를 진단한다
set -e

DB=$(docker ps --format '{{.Names}}' | grep massa | grep -i db | head -1)
echo "=== DB container: $DB ==="

docker exec -i "$DB" psql -U postgres -d postgres -v ON_ERROR_STOP=1 <<'SQL'
\pset pager off
SELECT tc.table_schema || '.' || tc.table_name AS child,
       kcu.column_name AS col,
       ccu.table_schema || '.' || ccu.table_name AS parent,
       rc.delete_rule
  FROM information_schema.table_constraints tc
  JOIN information_schema.key_column_usage kcu
    ON kcu.constraint_name = tc.constraint_name AND kcu.constraint_schema = tc.constraint_schema
  JOIN information_schema.referential_constraints rc
    ON rc.constraint_name = tc.constraint_name AND rc.constraint_schema = tc.constraint_schema
  JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name AND ccu.constraint_schema = tc.constraint_schema
 WHERE tc.constraint_type = 'FOREIGN KEY'
   AND tc.table_schema = 'public'
 ORDER BY parent, child;
SQL

echo "=== DIAG DONE ==="
