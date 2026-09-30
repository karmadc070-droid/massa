#!/bin/sh
# 운영 콘솔에 로그인할 수 있는 계정이 어느 것인지 본다.
# 비밀번호는 해시로만 저장돼 있어 볼 수 없고, 보려고 해서도 안 된다. 이메일만 확인한다.
set -e
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

echo '=== profiles.role 에 어떤 값이 있나 ==='
SQL "select role::text as 역할, count(*) as 명 from profiles group by 1 order by 2 desc;"

echo '=== 일반 고객이 아닌 계정 (이메일만) ==='
SQL "
select u.email, p.role::text as 역할, u.created_at::date as 가입일, u.last_sign_in_at::date as 최근로그인
from profiles p join auth.users u on u.id = p.id
where p.role::text <> 'customer'
order by 2, 3;
"
