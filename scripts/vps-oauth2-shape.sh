#!/bin/bash
# emoi oauth2-proxy 의 '모양' 만 본다. 비밀값은 전부 가린다.
for f in /root/emoi-oauth2/docker-compose.yml /root/oauth2-proxy/docker-compose.yml; do
  echo "=== $f ==="
  [ -f "$f" ] || { echo '  (없음)'; continue; }
  sed -E 's/(client-secret|client-id|cookie-secret|SECRET|CLIENT_ID|PASSWORD)[=: ]+.*/\1=***가림***/I' "$f" | sed 's/^/  /'
  echo
done
echo '=== 설정 파일이 따로 있나 ==='
ls -la /root/emoi-oauth2/ /root/oauth2-proxy/ 2>/dev/null | sed 's/^/  /'
