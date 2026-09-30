#!/bin/sh
# 허위 별점·후기 수를 지운다. (인증 마크는 앞 단계에서 이미 내렸다.)
#
# 주의 — 백업 테이블 providers_trust_backup_20260930 은 인증 마크를 내리기 *전* 값이다.
# 이 스크립트는 백업을 다시 만들지 않는다. 다시 만들면 원본 값을 잃는다.
#
# 원칙 — 숫자를 다른 숫자로 바꾸지 않는다. 근거 없는 표시를 없앨 뿐이다.
# 예약과 연결된 실제 후기가 없는 파트너는 별점·후기 수를 0 으로 두고, 화면에서는 '후기 없음' 으로 보이게 한다.
set -e
SQL() { docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c "$1"; }

echo '=== 백업 테이블이 살아 있는지 먼저 확인 ==='
SQL "select count(*) as 백업행수, count(*) filter (where is_verified) as 백업당시_인증마크 from providers_trust_backup_20260930;"

echo '=== 근거 없는 별점·후기 수 지우기 ==='
SQL "
update providers p
set rating = 0, review_count = 0
where not exists (
  select 1 from reviews r
  join bookings b on b.id = r.booking_id
  where r.provider_id = p.id
);
"

echo '=== 결과 ==='
SQL "
select
  count(*)                                             as 승인파트너,
  count(*) filter (where is_verified)                  as 인증마크남음,
  count(*) filter (where coalesce(review_count,0) > 0) as 후기표시남음,
  sum(coalesce(review_count,0))                        as 표시후기합계,
  count(*) filter (where hygiene_certified)            as 위생인증
from providers where application_status = 'approved';
"

echo '=== 인증 마크가 남은 파트너 ==='
SQL "
select p.display_name, p.rating, p.review_count, (k.provider_id is not null) as 서류있음
from providers p
left join provider_kyc k on k.provider_id = p.id
where p.application_status = 'approved' and p.is_verified;
"
