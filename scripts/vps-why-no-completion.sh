#!/bin/sh
# 예약 8건이 왜 전부 confirmed 에 멈춰 있는지 원인을 좁힌다.
# 후보 셋 — (1) 가짜/시드 데이터라 애초에 시술이 없었다 (2) 마사지사가 콘솔에 못 들어온다
# (3) RLS 가 update 를 막는데 코드에 오류 처리가 없어 조용히 실패한다.
# 읽기만 한다. ASCII 만 쓴다.
SQL() { docker exec -i massa-db psql -U postgres -d postgres "$@" < /dev/null; }

echo '=== 1. the 8 bookings — who, when, real or seed? ==='
SQL -c "
select b.created_at::date as created, b.scheduled_at, b.status::text,
       coalesce(p.display_name,'(none)') as provider,
       case when b.customer_id is null then 'no customer' else 'has customer' end as cust,
       b.amount_vnd, b.is_paid,
       b.scheduled_at < now() as past_due
from bookings b left join providers p on p.id=b.provider_id
order by b.created_at;"

echo ''
echo '=== 2. do those providers have a login account? ==='
SQL -c "
select p.display_name,
       (p.owner_id is not null) as has_owner,
       (p.profile_id is not null) as has_profile,
       coalesce(u.email,'(no auth user)') as email,
       u.last_sign_in_at
from bookings b
join providers p on p.id=b.provider_id
left join auth.users u on u.id = coalesce(p.owner_id, p.profile_id)
group by 1,2,3,4,5 order by 1;"

echo ''
echo '=== 3. RLS on bookings — can a provider update their own row? ==='
SQL -c "select relrowsecurity as rls_on from pg_class where relname='bookings';"
SQL -c "
select polname, polcmd,
       pg_get_expr(polqual, polrelid) as using_expr,
       pg_get_expr(polwithcheck, polrelid) as check_expr
from pg_policy where polrelid='bookings'::regclass order by polcmd, polname;"

echo ''
echo '=== 4. has any booking ever reached completed? (history check) ==='
SQL -c "select count(*) as ever_completed from bookings where completed_at is not null;"
