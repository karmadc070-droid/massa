#!/bin/sh
# 지정한 이메일 계정을 앱 관리자(admin)로 승격한다.
# 사용법: sh vps-grant-admin.sh someone@example.com
set -e

# noVNC 콘솔에서는 Shift 조합이 깨져 @ 를 입력할 수 없다. 기본값을 넣어 인자 없이 쓴다.
EMAIL="${1:-karmadc070@gmail.com}"

DB=$(docker ps --format '{{.Names}}' | grep massa | grep -i db | head -1)
echo "=== DB: $DB / 대상: $EMAIL ==="

docker exec -i "$DB" psql -U postgres -d postgres -v ON_ERROR_STOP=1 -v em="$EMAIL" <<'SQL'
\pset pager off
-- 대상 계정 존재 확인
SELECT u.id, u.email, p.role AS before_role
  FROM auth.users u LEFT JOIN public.profiles p ON p.id = u.id
 WHERE u.email = :'em';

-- profiles 행이 없으면 만들고, 있으면 role 만 올린다
INSERT INTO public.profiles (id, role)
SELECT u.id, 'admin' FROM auth.users u WHERE u.email = :'em'
ON CONFLICT (id) DO UPDATE SET role = 'admin';

SELECT u.email, p.role AS after_role
  FROM auth.users u JOIN public.profiles p ON p.id = u.id
 WHERE u.email = :'em';
SQL

echo "=== GRANT DONE ==="
