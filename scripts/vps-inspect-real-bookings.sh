#!/bin/sh
# 서류 없는 마사지사에게 들어간 예약 7건이 진짜 손님인지 시험용인지 가른다. 읽기만 한다.
# profiles 에 email 칸이 없다. auth.users 쪽을 본다.
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=0 <<'SQL'
\pset pager off
\echo '=== 그 7건의 정체 ==='
select to_char(b.created_at,'MM-DD HH24:MI') as 만든시각,
       b.status,
       p.display_name as 마사지사,
       coalesce(u.email,'(계정없음)') as 예약자,
       b.amount_vnd
  from public.bookings b
  join public.providers p on p.id = b.provider_id
  left join public.provider_kyc k on k.provider_id = p.id
  left join auth.users u on u.id = b.customer_id
 where k.provider_id is null
 order by b.created_at;

\echo ''
\echo '=== 전체 예약을 누가 만들었나 ==='
select coalesce(u.email,'(계정없음)') as 예약자, count(*)
  from public.bookings b left join auth.users u on u.id = b.customer_id
 group by 1 order by 2 desc;
SQL
