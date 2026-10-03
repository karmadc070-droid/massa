#!/bin/sh
# 후기 9건이 어디에 붙어 있고, 앱 화면에 실제로 보이는지 확인한다.
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

echo '=== providers 컬럼 이름 확인 (name 이 아니었다) ==='
SQL "select column_name from information_schema.columns
     where table_schema='public' and table_name='providers'
       and (column_name like '%name%' or column_name like '%rating%' or column_name like '%review%');"

echo ''
echo '=== 9건이 어디에 붙어 있나 ==='
SQL "
select (provider_id is not null) as 마사지사연결,
       (store_id    is not null) as 매장연결,
       count(*)
from reviews group by 1,2;
"

echo ''
echo '=== 그 대상들의 현재 노출 평점 ==='
SQL "
select p.id, p.rating, p.review_count, count(r.id) as 실제후기행
from providers p left join reviews r on r.provider_id = p.id
group by p.id, p.rating, p.review_count
having count(r.id) > 0 or coalesce(p.review_count,0) > 0
order by 4 desc;
"

echo ''
echo '=== 매장 쪽 ==='
SQL "
select s.id, s.rating, s.review_count, count(r.id) as 실제후기행
from stores s left join reviews r on r.store_id = s.id
group by s.id, s.rating, s.review_count
having count(r.id) > 0 or coalesce(s.review_count,0) > 0
order by 4 desc;
" 2>&1 | head -20
