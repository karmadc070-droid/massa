#!/bin/sh
# 애플 로그인 계정이 있는지, 관리자 권한이 어떻게 붙어 있는지 확인한다.
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
\echo '=== 지금 관리자·심사자 ==='
select pr.role::text as 역할, u.email as 계정,
       to_char(u.created_at at time zone 'Asia/Ho_Chi_Minh','YY-MM-DD') as 가입
  from public.profiles pr join auth.users u on u.id = pr.id
 where pr.role in ('admin','reviewer') order by pr.role::text, u.created_at;

\echo '=== 로그인 수단별 계정 수 ==='
select provider as 수단, count(*) from auth.identities group by 1 order by 2 desc;

\echo '=== 애플로 로그인한 계정 ==='
select u.email as 계정, pr.role::text as 역할,
       to_char(i.created_at at time zone 'Asia/Ho_Chi_Minh','YY-MM-DD HH24:MI') as 연결시각
  from auth.identities i
  join auth.users u on u.id = i.user_id
  left join public.profiles pr on pr.id = u.id
 where i.provider = 'apple' order by i.created_at;

\echo '=== icloud / privaterelay 주소를 쓰는 계정 ==='
select u.email as 계정, pr.role::text as 역할
  from auth.users u left join public.profiles pr on pr.id = u.id
 where u.email ilike '%icloud.com' or u.email ilike '%privaterelay.appleid.com'
 order by u.created_at;

\echo '=== 권한을 어떻게 보는가 (is_admin 정의) ==='
select pg_get_functiondef(p.oid) as 정의
  from pg_proc p join pg_namespace n on n.oid = p.pronamespace
 where n.nspname = 'public' and p.proname = 'is_admin';
PSQL
