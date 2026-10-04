#!/bin/sh
# block_duplicate_provider 가 이미 있는데 Thanh hà 는 4건이 들어왔다.
# 새로 만들기 전에 '왜 안 걸렸는가' 부터 본다. 있는 걸 또 만들면 두 개가 서로 싸운다.
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

echo '=== 1. 함수 본문 ==='
SQL "select pg_get_functiondef(p.oid)
     from pg_proc p join pg_namespace n on n.oid=p.pronamespace
     where n.nspname='public' and p.proname='block_duplicate_provider';"

echo ''
echo '=== 2. 트리거로 붙어 있나 (함수만 있고 안 붙었으면 아무 일도 안 한다) ==='
SQL "
select t.tgname, c.relname as 테이블, t.tgenabled as 활성,
       pg_get_triggerdef(t.oid) as 정의
from pg_trigger t join pg_class c on c.oid=t.tgrelid
where not t.tgisinternal and c.relname='providers';
"

echo ''
echo '=== 3. providers 에 유니크 제약이 있나 ==='
SQL "
select conname, contype, pg_get_constraintdef(oid)
from pg_constraint where conrelid='public.providers'::regclass;
"

echo ''
echo '=== 4. Thanh ha 4건의 실제 모습 ==='
SQL "
select id, display_name, phone, application_status::text, is_active, is_verified,
       owner_id, profile_id, created_at
from providers
where display_name ilike '%thanh%' order by created_at;
"

echo ''
echo '=== 5. 전화번호가 겹치는 다른 사례도 있나 ==='
SQL "
select phone, count(*), string_agg(display_name, ' | ')
from providers where phone is not null and phone <> ''
group by phone having count(*) > 1;
"
