#!/bin/sh
# 사이트·앱이 왜 느린지 서버 쪽에서 본다. 추측하지 말고 응답 헤더와 실제 바이트로 판단한다.
# SQL·출력 모두 ASCII 로 쓴다 (PowerShell 인코딩 문제).

echo '=== 1. compression: is gzip/brotli actually applied? ==='
for u in https://app.massaviet.com/ https://massaviet.com/ https://massaviet.com/style.css; do
  printf '%-42s ' "$u"
  H=$(curl -s -o /tmp/body -D- -H 'Accept-Encoding: gzip, br' --max-time 20 "$u")
  ENC=$(printf '%s' "$H" | grep -i '^content-encoding' | tr -d '\r' | cut -d' ' -f2)
  printf 'enc=%-8s bytes=%s\n' "${ENC:-NONE}" "$(wc -c < /tmp/body)"
done

echo ''
echo '=== 2. cache headers on static files ==='
for u in https://app.massaviet.com/ https://app.massaviet.com/icon-192.png https://massaviet.com/style.css; do
  printf '%-48s %s\n' "$u" "$(curl -s -o /dev/null -D- --max-time 20 "$u" | grep -i '^cache-control' | tr -d '\r')"
done

echo ''
echo '=== 3. provider photos: how many, how big, cached? ==='
docker exec -i massa-db psql -U postgres -d postgres -c "
select count(*) as providers_shown,
       count(*) filter (where photo_url like '%storage/v1%') as served_from_storage
from providers where is_active and application_status='approved';"

echo '  -- sample photo: size and headers --'
U=$(docker exec -i massa-db psql -U postgres -d postgres -tAc "
  select photo_url from providers
  where is_active and application_status='approved' and photo_url like 'http%'
  limit 1;")
echo "  $U"
curl -s -o /tmp/p -D/tmp/ph --max-time 30 "$U"
printf '  bytes=%s\n' "$(wc -c < /tmp/p)"
grep -iE 'content-type|cache-control|content-length' /tmp/ph | tr -d '\r' | sed 's/^/  /'

echo ''
echo '  -- total bytes of all shown provider photos --'
docker exec -i massa-db psql -U postgres -d postgres -tAc "
  select photo_url from providers
  where is_active and application_status='approved' and photo_url like 'http%';" \
| while read -r p; do
    [ -n "$p" ] && curl -s -o /dev/null -w '%{size_download} ' --max-time 20 "$p"
  done | awk '{t=0; for(i=1;i<=NF;i++) t+=$i; printf "  %d files, %.1f MB total\n", NF, t/1048576}'

echo ''
echo '=== 4. server load ==='
uptime
docker stats --no-stream --format '{{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}' | head -12

echo ''
echo '=== 5. db: slow? ==='
docker exec -i massa-db psql -U postgres -d postgres -c "\timing on" -c "
select count(*) from providers where is_active and application_status='approved';"
