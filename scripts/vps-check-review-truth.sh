#!/bin/sh
# 완료된 예약이 0건인데 후기가 9건이다. 앞서 고친 '허위 인증 마크' 와 같은 종류의 문제일 수 있다.
# 대시보드에 숫자를 올리기 전에 이 9건이 무엇인지부터 확인한다.
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

echo '=== reviews 컬럼 ==='
SQL "select column_name, data_type from information_schema.columns
     where table_schema='public' and table_name='reviews' order by ordinal_position;"

echo ''
echo '=== 후기 9건의 정체 — 예약과 연결돼 있나, 그 예약은 완료됐나 ==='
SQL "
select r.id,
       r.rating,
       (r.booking_id is not null) as 예약연결됨,
       b.status::text              as 예약상태,
       (b.completed_at is not null) as 완료됨,
       r.created_at::date          as 작성일
from reviews r left join bookings b on b.id = r.booking_id
order by r.created_at;
"

echo ''
echo '=== 마사지사 카드에 보이는 평점·후기수의 출처 ==='
SQL "select id, name, rating, review_count, is_verified, credential_verified
     from providers where coalesce(review_count,0) > 0 or coalesce(rating,0) > 0
     order by review_count desc nulls last limit 10;"
