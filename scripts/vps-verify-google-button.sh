#!/bin/sh
# 운영 콘솔에 구글 로그인 버튼이 실제로 서빙되는지 확인한다.
# 파일에만 있고 서빙되는 쪽에 없으면 배포가 안 된 것이다 — 둘 다 본다.
echo '=== 디스크 파일 ==='
printf '  auGoogle            %s\n' "$(grep -c auGoogle /srv/massa-admin/index.html)"
printf '  signInWithOAuth     %s\n' "$(grep -c signInWithOAuth /srv/massa-admin/index.html)"

echo '=== 서빙되는 쪽 (https) ==='
B=$(curl -s --max-time 25 https://admin.massaviet.com/)
printf '  크기                %s bytes\n' "$(printf '%s' "$B" | wc -c)"
printf '  버튼 문구           %s\n' "$(printf '%s' "$B" | grep -c '구글 계정으로 로그인')"
printf '  OAuth 호출          %s\n' "$(printf '%s' "$B" | grep -c signInWithOAuth)"

echo '=== 구글 공급자가 서버에 켜져 있나 ==='
curl -s --max-time 20 https://api.moahagwon.com/auth/v1/settings | tr ',' '\n' | grep -i google | sed 's/^/  /'
