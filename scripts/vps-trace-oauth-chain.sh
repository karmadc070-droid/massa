#!/bin/sh
# 구글 동의 화면이 안 뜨고 바로 앱으로 돌아온다. 어느 홉에서 꺾이는지 한 단계씩 본다.
# 브라우저는 앱이 해시를 지워버려서 오류를 볼 수 없다. curl 로 날것을 본다.
KEY=$(grep -E '^ANON_KEY=' /root/massa/.env | cut -d= -f2-)
UA='Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36'
URL="https://api.moahagwon.com/auth/v1/authorize?provider=google&redirect_to=https%3A%2F%2Fapp.massaviet.com%2F"

echo '=== 홉 1: /auth/v1/authorize ==='
H1=$(curl -s -o /dev/null -w '%{http_code} %{redirect_url}' --max-time 20 -A "$UA" -H "apikey: $KEY" "$URL")
echo "  $H1"
LOC=$(echo "$H1" | cut -d' ' -f2-)

echo ''
echo '=== 홉 2: 구글로 간 주소의 파라미터 ==='
echo "$LOC" | tr '&' '\n' | sed 's/^/  /' | head -12

echo ''
echo '=== 홉 2 응답 (구글이 뭐라 하는가) ==='
H2=$(curl -s -o /tmp/g.html -w '%{http_code} %{redirect_url}' --max-time 25 -A "$UA" "$LOC")
echo "  $H2"
echo '  --- 본문에 오류 문구가 있나 ---'
grep -oiE 'redirect_uri_mismatch|invalid_client|access_blocked|오류|error[^<]{0,80}' /tmp/g.html 2>/dev/null | head -5 | sed 's/^/  /'
head -c 300 /tmp/g.html | tr -d '\n' | sed 's/^/  /'

echo ''
echo ''
echo '=== 참고: GoTrue 가 쓰는 구글 redirect_uri ==='
docker exec massa-auth env | grep GOOGLE_REDIRECT_URI | sed 's/^/  /'
echo '  API_EXTERNAL_URL:'
docker exec massa-auth env | grep -E '^API_EXTERNAL_URL|^GOTRUE_API_EXTERNAL' | sed 's/^/  /'
