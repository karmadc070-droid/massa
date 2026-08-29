#!/bin/sh
# 운영 콘솔에 로그인 가능한 계정이 있는지 확인한다 (읽기 전용)
set -e
DB=$(docker ps --format '{{.Names}}' | grep massa | grep -i db | head -1)

docker exec -i "$DB" psql -U postgres -d postgres <<'SQL'
\pset pager off
SELECT COALESCE(p.role, '(없음)') AS role, count(*) AS cnt
  FROM auth.users u LEFT JOIN public.profiles p ON p.id = u.id
 GROUP BY 1 ORDER BY 2 DESC;

SELECT u.email, p.role
  FROM auth.users u LEFT JOIN public.profiles p ON p.id = u.id
 ORDER BY u.created_at;

SELECT 'provider owner' AS kind, u.email
  FROM public.providers pr JOIN auth.users u ON u.id = pr.owner_id
 GROUP BY u.email;
SQL
echo "=== ROLE CHECK DONE ==="
