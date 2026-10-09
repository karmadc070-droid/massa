#!/bin/bash
# providers 테이블에 누가 무엇을 쓸 수 있는지 본다. 읽기만 한다.
# 확인하려는 것 - 브라우저를 거치지 않고 API 로 직접 'approved' 를 써넣을 수 있는가.
set -e
Q() { docker exec -i massa-db psql -U postgres -d postgres -c "$1" < /dev/null; }

echo '=== providers RLS 정책 ==='
Q "select policyname, cmd, roles::text,
          coalesce(qual,'-')      as using_조건,
          coalesce(with_check,'-') as withcheck_조건
     from pg_policies
    where tablename='providers' order by cmd, policyname;"

echo '=== RLS 켜져 있나 ==='
Q "select relname, relrowsecurity from pg_class where relname in ('providers','provider_kyc');"

echo '=== anon / authenticated 역할의 테이블 권한 ==='
Q "select grantee, privilege_type from information_schema.role_table_grants
    where table_name='providers' and grantee in ('anon','authenticated')
    order by grantee, privilege_type;"
