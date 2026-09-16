#!/bin/sh
# 서류 없는 21명이 실제로 손님에게 어떻게 보이는지 확인한다. 읽기만 한다.
#
# 앱 설명에 이렇게 써 있다:
#   "인증 마크 — 자격증 확인, 신원 확인, 대면 면접 3단계를 통과한 테라피스트에게만 부여합니다"
# 서류가 없는 사람에게 그 마크가 붙어 있으면 손님에게 거짓말을 하고 있는 것이다.
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=0 <<'SQL'
\pset pager off
\echo '=== 서류 유무 × 인증마크 × 노출 여부 ==='
select
  case when k.provider_id is null then '서류 없음' else '서류 있음' end as 서류,
  count(*)                                   as 인원,
  count(*) filter (where p.is_verified)      as 인증마크붙음,
  count(*) filter (where p.is_active)        as 앱에노출됨,
  count(*) filter (where p.hygiene_certified) as 위생인증
from public.providers p
left join public.provider_kyc k on k.provider_id = p.id
where p.application_status = 'approved'
group by 1;

\echo ''
\echo '=== 이 사람들에게 실제 예약이 들어온 적 있나 ==='
select count(*) as 예약건수,
       count(distinct b.provider_id) as 해당마사지사수
  from public.bookings b
  join public.providers p on p.id = b.provider_id
  left join public.provider_kyc k on k.provider_id = p.id
 where k.provider_id is null;

\echo ''
\echo '=== 진짜 사람인지 시드인지 — 로그인 계정이 붙어 있나 ==='
select
  count(*)                                                   as 서류없는파트너,
  count(*) filter (where p.profile_id is not null)           as 프로필연결됨,
  count(*) filter (where p.owner_id   is not null)           as 소유자연결됨,
  count(*) filter (where p.profile_id is null and p.owner_id is null) as 계정없음
from public.providers p
left join public.provider_kyc k on k.provider_id = p.id
where p.application_status='approved' and k.provider_id is null;
SQL
