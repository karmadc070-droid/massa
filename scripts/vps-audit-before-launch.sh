#!/bin/sh
# 출시 직전 실태 재확인 — 읽기 전용이다. 아무것도 바꾸지 않는다.
# 컬럼 이름은 실제 스키마에서 확인한 것이다. providers 의 상태 컬럼은 application_status 다.
set -e
SQL() { docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c "$1"; }

echo '=== 0. application_status 값 분포 ==='
SQL "select application_status, count(*) from providers group by 1 order by 2 desc;"

echo '=== 1. 승인 파트너 / KYC 서류 / 인증 마크 ==='
SQL "
select
  count(*)                                                        as 승인파트너,
  count(*) filter (where k.provider_id is null)                   as 서류없음,
  count(*) filter (where p.is_verified)                           as 인증마크붙음,
  count(*) filter (where p.is_verified and k.provider_id is null) as 서류없는데인증마크,
  count(*) filter (where p.hygiene_certified)                     as 위생인증,
  count(*) filter (where p.is_active)                             as 앱에노출중
from providers p
left join provider_kyc k on k.provider_id = p.id
where p.application_status = 'approved';
"

echo '=== 2. 후기 — 실제 저장된 행 vs 화면에 표시되는 수 ==='
SQL "select count(*) as reviews_행수, count(*) filter (where booking_id is not null) as 예약연결됨 from reviews;"
SQL "
select count(*) as 파트너수, sum(review_count) as 표시후기합계,
       round(avg(nullif(rating,0))::numeric,2) as 평균표시별점
from providers where application_status = 'approved';
"

echo '=== 3. 표시 후기 수가 실제보다 많은 파트너 상위 10 ==='
SQL "
select p.display_name, p.rating as 표시별점, p.review_count as 표시후기,
       (select count(*) from reviews r where r.provider_id = p.id) as 실제후기,
       p.is_verified as 인증마크
from providers p
where p.application_status = 'approved'
order by p.review_count desc nulls last
limit 10;
"

echo '=== 4. 계정 주인 ==='
SQL "
select coalesce(u.email,'(계정 없음)') as 계정, count(*) as 명
from providers p
left join auth.users u on u.id = p.owner_id
where p.application_status = 'approved'
group by 1 order by 2 desc;
"
