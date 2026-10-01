#!/bin/sh
# /auth/v1/settings 는 apikey 없이는 Unauthorized 를 준다. anon 키를 붙여서 구글 공급자 상태를 본다.
KEY=$(grep -E '^ANON_KEY=' /root/massa/.env | cut -d= -f2-)
[ -n "$KEY" ] || { echo 'ANON_KEY 를 .env 에서 못 찾았다'; grep -nE 'ANON|JWT' /root/massa/.env | cut -d= -f1; exit 1; }
echo '=== external 공급자 목록 ==='
curl -s --max-time 20 -H "apikey: $KEY" https://api.moahagwon.com/auth/v1/settings \
  | tr ',{}' '\n' | grep -E 'google|apple|email' | sed 's/^/  /'
echo '=== 컨테이너 환경변수 (값은 가린다) ==='
docker exec massa-auth env | grep -E 'GOOGLE' | sed 's/=.*/=(설정됨)/' | sed 's/^/  /'
