#!/bin/sh
# Kun, Trang 두 분을 목록 위로 올린다. 거짓 표시는 쓰지 않고 '노출 순서' 만 바꾼다.
# sort_priority 를 새로 둔다 — 지금은 rating 순인데 전원 0 이라 사실상 무작위다.
# PowerShell 이 한글을 깨뜨리므로 SQL 안에는 ASCII 만 쓴다 (기록된 교훈).
SQL() { docker exec -i massa-db psql -U postgres -d postgres -c "$1"; }

echo '=== 0. before: profile fields ==='
SQL "
select display_name, application_status::text as status, is_active,
       coalesce(nullif(photo_url,''),'(none)') as photo,
       coalesce(array_length(photo_urls,1),0) as photos,
       coalesce(nullif(left(bio,30),''),'(none)') as bio,
       coalesce(array_length(specialties,1),0) as specialties,
       coalesce(array_length(languages,1),0) as languages,
       coalesce(nullif(base_district,''),'(none)') as district,
       review_count, rating
from providers
where display_name ilike '%kun%' or display_name ilike '%trang%'
order by display_name;
"

echo ''
echo '=== 1. add sort_priority column (default 0, nothing else changes) ==='
SQL "alter table providers add column if not exists sort_priority int not null default 0;"

echo ''
echo '=== 2. raise the two signups to the top ==='
SQL "
update providers set sort_priority = 100
where display_name ilike '%kun%' or display_name ilike '%trang%';
"

echo ''
echo '=== 3. after: who sits on top of the customer list ==='
SQL "
select display_name, sort_priority, application_status::text as status, is_active,
       case when is_active and application_status='approved'
            then 'SHOWN' else 'HIDDEN' end as customer_view
from providers
order by sort_priority desc, rating desc nulls last, display_name
limit 8;
"
