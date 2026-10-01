#!/bin/sh
# 구글 로그인을 붙이기 전에 확인한다.
# 가장 중요한 질문 — 구글로 로그인하면 **기존 admin 계정에 붙는가, 새 계정이 생기는가.**
# 새 계정이 생기면 role 이 없어서 관리자 화면이 하나도 안 보인다. 지금보다 나빠진다.
set -e
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

echo '=== 1. 구글 로그인이 서버에 켜져 있나 ==='
grep -E 'GOOGLE|EXTERNAL' /root/massa/docker-compose.yml | sed 's/\(SECRET[^ ]*\).*/\1=***/' | sed 's/^/  /' || echo '  설정 없음'
echo '  --- .env 쪽 (값은 가린다) ---'
grep -E '^GOTRUE_EXTERNAL_GOOGLE|^GOOGLE_' /root/massa/.env | sed 's/=.*/=(설정됨)/' | sed 's/^/  /' || echo '  설정 없음'

echo ''
echo '=== 2. 계정 상태 — 이메일이 확인된 계정이어야 구글 로그인이 같은 계정에 붙는다 ==='
SQL "
select u.email,
       (u.email_confirmed_at is not null) as 이메일확인됨,
       p.role::text as 역할,
       u.created_at::date as 가입일
from auth.users u left join profiles p on p.id = u.id
where u.email = 'karmadc070@gmail.com';
"

echo ''
echo '=== 3. 이 계정에 이미 붙어 있는 로그인 수단 ==='
SQL "
select i.provider, i.created_at::date as 연결일
from auth.identities i join auth.users u on u.id = i.user_id
where u.email = 'karmadc070@gmail.com';
"

echo ''
echo '=== 4. 같은 메일로 계정이 두 개 생긴 적은 없나 ==='
SQL "select email, count(*) from auth.users group by 1 having count(*) > 1;"
