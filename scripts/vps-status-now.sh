#!/bin/sh
# '다음에 뭘 해야 하나' 를 기억이 아니라 현재 데이터로 답하기 위한 조회. 읽기만 한다.
# PowerShell 이 한글을 깨뜨리므로 SQL 안에는 ASCII 만 쓴다.
SQL() { docker exec -i massa-db psql -U postgres -d postgres "$@" < /dev/null; }

echo '=== 1. business reality ==='
SQL -c "
select (select count(*) from providers where is_active and application_status='approved') as shown_providers,
       (select count(*) from providers where application_status='pending') as pending_apps,
       (select count(*) from bookings) as bookings_total,
       (select count(*) from bookings where status='completed') as bookings_done,
       (select count(*) from reviews) as reviews_total,
       (select count(distinct device_id) from app_visit) as devices;"

echo ''
echo '=== 2. bookings by status ==='
SQL -c "select status::text, count(*) from bookings group by 1 order by 2 desc;"

echo ''
echo '=== 3. reviews still on screen (these are the seeded ones) ==='
SQL -c "
select p.display_name, count(*) as reviews, round(avg(r.rating),1) as avg
from reviews r join providers p on p.id=r.provider_id
group by 1 order by 2 desc;"

echo ''
echo '=== 4. providers missing documents but shown to customers ==='
SQL -c "
select count(*) filter (where k.provider_id is null) as no_kyc_row,
       count(*) filter (where k.provider_id is not null
                          and coalesce(k.id_front_url,'')=''
                          and coalesce(k.cert_url,'')=''
                          and coalesce(k.business_license_url,'')='') as kyc_row_but_empty,
       count(*) filter (where p.is_verified) as verified_mark_on
from providers p
left join provider_kyc k on k.provider_id=p.id
where p.is_active and p.application_status='approved';"

echo ''
echo '=== 5. profile gallery photos still full size ==='
SQL -c "
select count(*) as providers_with_gallery,
       sum(coalesce(array_length(photo_urls,1),0)) as gallery_photos
from providers where is_active and application_status='approved';"

echo ''
echo '=== 6. app static cache headers (none = refetched every visit) ==='
for p in "" sw.js icon-192.png; do
  printf '  %-34s %s\n' "/$p" \
    "$(curl -s -o /dev/null -D- --max-time 15 "https://app.massaviet.com/$p" | grep -i '^cache-control' | tr -d '\r' || echo '(none)')"
done

echo ''
echo '=== 7. old hosts still serving (Vercel exit) ==='
for u in https://massa-seven.vercel.app/ https://massa.moahagwon.com/ https://api.moahagwon.com/auth/v1/health; do
  printf '  %-46s %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "$u")"
done
