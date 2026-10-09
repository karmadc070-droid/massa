#!/bin/bash
# 가입자 목록을 만들기 전에 profiles 에 무엇이 있는지 본다. 읽기만 한다.
Q() { docker exec -i massa-db psql -U postgres -d postgres -c "$1" < /dev/null; }

echo '=== profiles 컬럼 ==='
Q "select column_name, data_type from information_schema.columns
    where table_name='profiles' order by ordinal_position;"

echo '=== 몇 명인가 ==='
Q "select count(*) from profiles;"

echo '=== is_admin / is_reviewer 함수 내용 ==='
Q "select proname, prosrc from pg_proc where proname in ('is_admin','is_reviewer');"

echo '=== 관리자 계정이 누구인가 ==='
Q "select id, role::text from profiles where role::text <> 'user' limit 10;"
