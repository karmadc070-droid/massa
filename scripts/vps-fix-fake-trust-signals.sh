#!/bin/sh
# 출시 전 허위 신뢰 표시를 내린다 — 인증 마크와 별점·후기 수.
#
# 왜 하는가: 승인 파트너 22명 중 21명은 provider_kyc 서류가 아예 없는데 전원 인증 마크가 붙어 있고,
# 화면에 표시되는 후기가 합계 1,775건인데 예약과 연결된 실제 후기는 0건이다.
# 스토어 설명은 '3단계 검증'과 '서비스 받은 고객만 후기'를 약속하고 있다. 지금 공개하면 그게 허위 광고가 된다.
#
# 원칙 — 숫자를 다른 숫자로 바꾸지 않는다. 근거 없는 표시를 없앨 뿐이다.
# 되돌릴 수 있도록 바꾸기 전 값을 백업 테이블에 남긴다.
set -e
SQL() { docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 -c "$1"; }

echo '=== 0. 백업 (providers_trust_backup_20260930) ==='
SQL "
drop table if exists providers_trust_backup_20260930;
create table providers_trust_backup_20260930 as
select id, display_name, is_verified, rating, review_count, hygiene_certified, now() as backed_up_at
from providers;
select count(*) as 백업행수 from providers_trust_backup_20260930;
"

echo '=== 1. 서류 없는 파트너의 인증 마크 내리기 ==='
SQL "
update providers p
set is_verified = false
where not exists (select 1 from provider_kyc k where k.provider_id = p.id)
  and p.is_verified;
"

echo '=== 2. 근거 없는 별점·후기 수 지우기 ==='
-- 예약과 연결된 실제 후기가 없는 파트너는 별점과 후기 수를 표시하지 않는다.
SQL "
update providers p
set rating = 0, review_count = 0
where not exists (
  select 1 from reviews r
  join bookings b on b.id = r.booking_id
  where r.provider_id = p.id
);
"

echo '=== 3. 결과 확인 ==='
SQL "
select
  count(*)                                      as 승인파트너,
  count(*) filter (where is_verified)           as 인증마크남음,
  count(*) filter (where coalesce(review_count,0) > 0) as 후기표시남음,
  sum(coalesce(review_count,0))                 as 표시후기합계,
  count(*) filter (where hygiene_certified)     as 위생인증
from providers where application_status = 'approved';
"

echo '=== 4. 인증 마크가 남은 파트너 (서류가 실제로 있는 사람) ==='
SQL "
select p.display_name, p.is_verified, p.rating, p.review_count,
       (k.provider_id is not null) as 서류있음
from providers p
left join provider_kyc k on k.provider_id = p.id
where p.application_status = 'approved' and p.is_verified;
"
