#!/bin/sh
# 애플 계정을 구글 계정으로 합치기 전에, 애플 계정에 딸린 데이터가 있는지 본다.
# 데이터가 있으면 옮겨야 하고, 없으면 신원만 옮기면 된다.
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
select id as apple from auth.users where email = 'karmadc77@icloud.com' \gset
select id as goog  from auth.users where email = 'karmadc070@gmail.com' \gset

\echo '=== 두 계정 ==='
select case when id = :'apple' then '애플' else '구글' end as 구분,
       email, left(id::text,8) as id,
       to_char(created_at at time zone 'Asia/Ho_Chi_Minh','YY-MM-DD HH24:MI') as 가입
  from auth.users where id in (:'apple', :'goog');

\echo '=== 애플 계정에 딸린 데이터 (0 이면 그냥 신원만 옮기면 된다) ==='
select 'profiles'  as 표, count(*) from public.profiles  where id = :'apple'
union all select 'bookings',   count(*) from public.bookings   where customer_id = :'apple'
union all select 'favorites',  count(*) from public.favorites  where customer_id = :'apple'
union all select 'messages',   count(*) from public.messages   where customer_id = :'apple'
union all select 'reviews',    count(*) from public.reviews    where customer_id = :'apple'
union all select 'reports',    count(*) from public.reports    where reporter_id = :'apple'
union all select 'providers(profile_id)', count(*) from public.providers where profile_id = :'apple'
union all select 'providers(owner_id)',   count(*) from public.providers where owner_id   = :'apple';

\echo '=== 애플 계정을 가리키는 다른 외래키가 더 있는지 (자동 탐색) ==='
select c.conrelid::regclass::text as 표, a.attname as 칸
  from pg_constraint c
  join pg_attribute a on a.attrelid = c.conrelid and a.attnum = c.conkey[1]
 where c.contype = 'f'
   and c.confrelid in ('auth.users'::regclass, 'public.profiles'::regclass)
   and c.conrelid::regclass::text not like 'auth.%'
 order by 1, 2;

\echo '=== 두 계정의 신원(identities) ==='
select case when user_id = :'apple' then '애플계정' else '구글계정' end as 소속,
       provider as 수단, left(provider_id, 12) as 식별자앞
  from auth.identities where user_id in (:'apple', :'goog') order by 1, 2;
PSQL
