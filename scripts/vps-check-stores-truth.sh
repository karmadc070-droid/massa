#!/bin/sh
# 스파 안내(매장 목록)에 별점·조회수·'위생 인증' 배지가 붙어 있다.
# 앞서 마사지사 쪽에서 걷어낸 허위 신뢰 신호와 같은 종류인지 확인한다.
# 코드의 목업은 DB 에 있는 카테고리만 덮어쓴다(Object.assign). 나머지는 가짜가 그대로 남는다.
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

echo '=== stores 컬럼 ==='
SQL "select column_name, data_type from information_schema.columns
     where table_schema='public' and table_name='stores' order by ordinal_position;"

echo ''
echo '=== DB 에 든 매장 8곳의 실체 ==='
SQL "select name, category, rating, view_count, discount_pct, badges, created_at::date
     from stores order by category, name;"

echo ''
echo '=== 이 매장들에 실제 후기가 있나 ==='
SQL "select s.name, s.rating as 표시평점, s.view_count as 표시조회수,
            count(r.id) as 실제후기
     from stores s left join reviews r on r.store_id = s.id
     group by s.name, s.rating, s.view_count order by 4 desc, 1;"

echo ''
echo '=== 매장 예약이 한 건이라도 있나 ==='
SQL "select count(*) as 매장예약 from bookings where store_id is not null;"
