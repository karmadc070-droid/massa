#!/bin/sh
# 앱(index.html)을 실제로 서비스하는 주소가 어디인지 본다. 배포 대상을 빠뜨리지 않기 위해서다.
# 판별 방법 — 이번에 고친 문구 '아직 후기 없음' 이 들어 있는지로 최신 여부를 본다.
for U in https://app.massaviet.com/ https://massa.moahagwon.com/ https://massa-seven.vercel.app/; do
  CODE=$(curl -s -o /tmp/p.html -w '%{http_code}' --max-time 20 "$U")
  SIZE=$(wc -c < /tmp/p.html)
  NEW=$(grep -c '아직 후기 없음' /tmp/p.html || true)
  OLD=$(grep -c 'tstars">★ ' /tmp/p.html || true)
  printf '%-36s %s  %8s bytes  최신문구:%s  옛문구:%s\n' "$U" "$CODE" "$SIZE" "$NEW" "$OLD"
done

echo ''
echo '=== Caddy 가 각 도메인에 물린 디렉터리 ==='
grep -A3 -E '^(app\.massaviet\.com|massa\.moahagwon\.com)' /etc/caddy/Caddyfile | grep -E 'massaviet|root|^\S' | sed 's/^/  /'
