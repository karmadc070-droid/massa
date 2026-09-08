#!/bin/sh
# 일괄 승인 함수를 넣고, 심사 대기 마사지사 명단을 뽑는다.
set -e
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < /root/price_bulk_approve.sql
docker exec -i massa-db psql -U postgres -d postgres -c "notify pgrst, 'reload schema'"

echo ''
echo '=== 심사 대기 명단 ==='
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
select p.display_name as 이름,
       p.kind::text as 구분,
       to_char(p.created_at at time zone 'Asia/Ho_Chi_Minh', 'MM-DD HH24:MI') as 신청시각,
       coalesce(u.email, '(계정 없음)') as 계정,
       coalesce(p.base_district, '-') as 지역,
       case when p.photo_url is null and coalesce(array_length(p.photo_urls,1),0)=0
            then '없음' else '있음' end as 사진,
       coalesce(left(p.bio, 24), '-') as 소개
  from public.providers p
  left join auth.users u on u.id = coalesce(p.profile_id, p.owner_id)
 where p.application_status = 'pending'
 order by p.created_at;

\echo '--- 계정별로 몇 건씩 넣었나 ---'
select coalesce(u.email, '(계정 없음)') as 계정, count(*) as 신청건수
  from public.providers p
  left join auth.users u on u.id = coalesce(p.profile_id, p.owner_id)
 where p.application_status = 'pending'
 group by 1 order by 2 desc;

\echo '--- 대기자들의 실제 활동 흔적 (0 이면 시험 데이터) ---'
select p.display_name as 이름,
       (select count(*) from public.bookings b where b.provider_id = p.id) as 예약,
       (select count(*) from public.reviews  r where r.provider_id = p.id) as 리뷰,
       (select count(*) from public.messages m where m.provider_id = p.id) as 채팅
  from public.providers p
 where p.application_status = 'pending'
 order by p.created_at;
PSQL
