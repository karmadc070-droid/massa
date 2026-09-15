#!/bin/sh
# 앱이 실제로 어느 주소들에서 서비스되고 있는지, 인증이 어느 주소를 허용하는지 본다.
# 옮기기 전에 '지금 무엇이 걸려 있는가'를 먼저 안다. 추측하지 않는다.

echo '=== 1. Caddy 가 서빙하는 도메인 ==='
grep -nE '^[a-z0-9.*-]+\.[a-z]{2,}[[:space:]]*\{' /root/Caddyfile | sed 's/^/  /'

echo ''
echo '=== 2. massa.moahagwon.com 이 무엇을 가리키나 ==='
awk '/^massa\.moahagwon\.com/,/^}/' /root/Caddyfile | sed 's/^/  /'

echo ''
echo '=== 3. GoTrue 가 허용하는 리디렉트 (값 그대로 — 비밀 아님) ==='
grep -E '^(SITE_URL|ADDITIONAL_REDIRECT_URLS|API_EXTERNAL_URL|SUPABASE_PUBLIC_URL)=' /root/massa/.env | sed 's/^/  /'

echo ''
echo '=== 4. 어떤 소셜 로그인이 켜져 있나 (켜짐/꺼짐만) ==='
grep -E '^(GOOGLE|APPLE|KAKAO|AZURE|FACEBOOK)_ENABLED=' /root/massa/.env | sed 's/^/  /'
echo '  --- 리디렉트 URI 설정값 ---'
grep -E '^[A-Z]+_REDIRECT_URI=' /root/massa/.env | sed 's/^/  /'

echo ''
echo '=== 5. 컨테이너에 들어간 실제 값 ==='
docker exec massa-auth sh -c 'echo "  SITE_URL=$GOTRUE_SITE_URL"; echo "  URI_ALLOW_LIST=$GOTRUE_URI_ALLOW_LIST"' 2>/dev/null || echo '  (massa-auth 조회 실패)'

echo ''
echo '=== 6. 세 주소가 각각 살아 있나 ==='
for h in app.massaviet.com massa.moahagwon.com massaviet.com; do
  printf '  %-26s ' "$h"
  curl -s -o /dev/null -w '%{http_code}\n' "https://$h/" || echo 실패
done
