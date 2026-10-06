#!/bin/sh
# 옛 주소로 들어오는 65건·19건이 진짜 손님인지, 우리 점검 스크립트인지 가린다.
# 우리 curl 이면 닫아도 되고, 진짜 브라우저면 닫으면 안 된다.
C=$(docker ps --format '{{.Names}}' | grep -i caddy | head -1)

for H in massa.moahagwon.com massa-seven.vercel.app; do
  echo "=== $H ==="
  docker logs --since 168h "$C" 2>&1 | grep "$H" > /tmp/h.log
  printf '  전체 %s건\n' "$(wc -l < /tmp/h.log)"
  echo '  -- 사용자 에이전트 --'
  grep -oE '"User-Agent":\["[^"]*"' /tmp/h.log | sed 's/.*\["//' | cut -c1-55 | sort | uniq -c | sort -rn | head -6
  echo '  -- 요청 경로 --'
  grep -oE '"uri":"[^"]*"' /tmp/h.log | sed 's/"uri":"//;s/"$//' | cut -c1-40 | sort | uniq -c | sort -rn | head -6
  echo ''
done

echo '=== massaviet.com 네임서버 (DNS 를 어디서 관리하나) ==='
( command -v dig >/dev/null && dig +short NS massaviet.com ) \
  || ( command -v nslookup >/dev/null && nslookup -type=NS massaviet.com | grep -i nameserver ) \
  || echo '  dig/nslookup 없음'
echo ''
echo '=== moahagwon.com 네임서버 ==='
( command -v dig >/dev/null && dig +short NS moahagwon.com ) || echo '  -'

echo ''
echo '=== DB 안에 api.moahagwon.com 이 박힌 주소가 몇 건인가 (도메인 이전의 진짜 비용) ==='
docker exec -i massa-db psql -U postgres -d postgres -c "
select 'providers.photo_url' as col, count(*) from providers where photo_url like '%api.moahagwon.com%'
union all select 'providers.photo_urls', count(*) from providers p, lateral unnest(coalesce(p.photo_urls,'{}')) u(x) where u.x like '%api.moahagwon.com%'
union all select 'providers.photo_url_orig', count(*) from providers where photo_url_orig like '%api.moahagwon.com%'
union all select 'provider_kyc(문서)', count(*) from provider_kyc where coalesce(id_front_url,'')||coalesce(id_back_url,'')||coalesce(cert_url,'')||coalesce(business_license_url,'') like '%api.moahagwon.com%';
" < /dev/null
