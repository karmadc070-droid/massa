#!/bin/sh
# 서류 없는 21명을 '실제 사람'과 '시드'로 갈라 명단을 뽑는다. 읽기만 한다.
# 가르는 기준: 로그인 계정(owner_id 또는 profile_id)이 붙어 있으면 실제 사람이다.
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=0 <<'SQL'
\pset pager off
\pset border 2

\echo '################ A. 실제 사람 — 계정이 붙어 있다 (서류만 없음) ################'
select p.display_name as 이름, p.kind as 구분, p.base_district as 권역,
       to_char(p.created_at,'MM-DD') as 가입,
       coalesce(p.phone,'-') as 전화,
       coalesce(u.email,'-') as 로그인계정,
       p.rating as 평점, p.review_count as 후기
  from public.providers p
  left join public.provider_kyc k on k.provider_id = p.id
  left join auth.users u on u.id = coalesce(p.owner_id, p.profile_id)
 where p.application_status='approved' and k.provider_id is null
   and (p.owner_id is not null or p.profile_id is not null)
 order by p.created_at, p.display_name;

\echo ''
\echo '################ B. 시드 — 계정이 아예 없다 ################'
select p.display_name as 이름, p.kind as 구분, p.base_district as 권역,
       to_char(p.created_at,'MM-DD') as 가입,
       coalesce(p.phone,'-') as 전화,
       p.rating as 평점, p.review_count as 후기,
       (select count(*) from public.bookings b where b.provider_id=p.id) as 예약
  from public.providers p
  left join public.provider_kyc k on k.provider_id = p.id
 where p.application_status='approved' and k.provider_id is null
   and p.owner_id is null and p.profile_id is null
 order by p.created_at, p.display_name;

\echo ''
\echo '################ C. 서류가 있는 사람 (정상) ################'
select p.display_name as 이름, p.base_district as 권역,
       coalesce(u.email,'-') as 로그인계정
  from public.providers p
  join public.provider_kyc k on k.provider_id = p.id
  left join auth.users u on u.id = coalesce(p.owner_id, p.profile_id)
 where p.application_status='approved';

\echo ''
\echo '################ D. 후기·평점이 진짜인가 ################'
select count(*) as 전체후기,
       count(*) filter (where r.booking_id is not null) as 예약에붙은후기
  from public.reviews r;
SQL
