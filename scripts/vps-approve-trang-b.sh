#!/bin/sh
# Trang B. 를 승인한다. 그리고 깨진 자리표시자 사진을 치운다.
#
# photo_url 이 'https://example.com/trang.jpg' 다. 승인해서 손님 화면에 올리면
# 그 자리에 깨진 이미지가 뜬다. NULL 로 비우면 avatarFor() 가 기본 아바타를 쓴다 —
# 사진 없는 다른 마사지사와 같은 처리다. 원래 값은 photo_url_orig 에 남아 있다.
SQL() { docker exec -i massa-db psql -U postgres -d postgres "$@" < /dev/null; }

echo '=== before ==='
SQL -c "
select display_name, application_status::text as status, is_active, sort_priority,
       coalesce(photo_url,'(null)') as photo, coalesce(photo_url_orig,'(null)') as photo_orig
from providers where display_name ilike '%trang%' order by display_name;"

echo ''
echo '=== 1. approve ==='
SQL -c "
update providers
set application_status = 'approved', reviewed_at = now()
where display_name = 'Trang B.' and application_status = 'pending';"

echo ''
echo '=== 2. clear the placeholder photo (keeps photo_url_orig) ==='
SQL -c "
update providers
set photo_url = null
where display_name = 'Trang B.' and photo_url like '%example.com%';"

echo ''
echo '=== after — 손님 화면에 뜨는가 ==='
SQL -c "
select display_name, application_status::text as status, is_active, sort_priority,
       coalesce(photo_url,'(null -> 기본 아바타)') as photo,
       case when is_active and application_status='approved' then 'SHOWN' else 'HIDDEN' end as customer_view
from providers where display_name ilike '%trang%' or display_name ilike '%kun%'
order by sort_priority desc, display_name;"

echo ''
echo '=== 노출 중인 마사지사 총원 ==='
SQL -c "select count(*) from providers where is_active and application_status='approved';"
