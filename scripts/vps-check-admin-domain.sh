#!/bin/sh
# 운영 콘솔을 massaviet.com 쪽으로 옮기기 전에 확인한다.
# 확인할 것 — 새 이름의 DNS 가 이미 있는지, 지금 어떤 이름들이 Caddy 에 물려 있는지,
#             그리고 GoTrue 허용목록에 새 주소가 들어 있는지(없으면 비밀번호 재설정이 깨진다).
echo '=== 1. DNS ==='
for D in admin.massaviet.com app.massaviet.com massaviet.com admin.moahagwon.com; do
  printf '  %-24s A=%s\n' "$D" "$(dig +short A "$D" | tr '\n' ' ')"
done

echo ''
echo '=== 2. Caddy 에 등록된 사이트 이름 ==='
grep -nE '^[a-z0-9.-]+\.[a-z]+ \{' /root/Caddyfile | sed 's/^/  /'

echo ''
echo '=== 3. 운영 콘솔이 어디서 서빙되나 ==='
grep -n -A6 'admin.moahagwon.com' /root/Caddyfile | sed 's/^/  /'

echo ''
echo '=== 4. GoTrue 허용목록 (새 주소를 반드시 넣어야 한다) ==='
grep -o 'GOTRUE_URI_ALLOW_LIST[^"]*' /root/massa/docker-compose.yml | tr ',' '\n' | sed 's/^/  /'
