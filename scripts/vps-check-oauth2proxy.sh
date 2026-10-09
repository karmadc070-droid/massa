#!/bin/bash
# emoi 가 쓰는 oauth2-proxy 를 massaviet.com 에도 쓸 수 있는지 본다. 읽기만 한다.
echo '=== 돌고 있는 컨테이너 ==='
docker ps --format '{{.Names}}\t{{.Image}}\t{{.Ports}}' | grep -iE 'oauth|proxy' || echo '  (oauth 관련 없음)'

echo ''
echo '=== oauth2-proxy 설정 (비밀값은 가린다) ==='
C=$(docker ps --format '{{.Names}}' | grep -i oauth | head -1)
if [ -n "$C" ]; then
  docker inspect "$C" --format '{{range .Config.Env}}{{println .}}{{end}}' \
   | grep -iE 'REDIRECT|COOKIE_DOMAIN|WHITELIST|EMAIL|UPSTREAM|PROVIDER|HTTP_ADDRESS' \
   | sed -E 's/(SECRET|CLIENT_ID)=.*/\1=***가림***/' | sed 's/^/  /'
else
  echo '  컨테이너를 못 찾음'
fi

echo ''
echo '=== 어디서 띄우나 (compose 파일) ==='
grep -rl 'oauth2' /root/*.yml /root/*/*.yml 2>/dev/null | head -3
