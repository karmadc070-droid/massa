#!/bin/sh
# Caddy 가 실제로 어느 설정 파일을 읽고 있는지 찾는다.
# /root/Caddyfile 을 고치고 reload 했는데 적용이 안 됐다 — 보는 파일이 다를 수 있다.
echo '=== 마운트 ==='
docker inspect caddy --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}'

echo '=== 실행 명령 ==='
docker inspect caddy --format '{{.Path}} {{range .Args}}{{.}} {{end}}'

echo ''
echo '=== 컨테이너 안의 Caddyfile 들 ==='
docker exec caddy sh -c 'ls -la /etc/caddy/ 2>/dev/null; echo "---"; ls -la /root/Caddyfile 2>/dev/null'

echo ''
echo '=== 컨테이너가 보는 설정에 리다이렉트가 들어갔나 ==='
docker exec caddy sh -c 'grep -n "massa-old-retired\|massa.moahagwon.com" /etc/caddy/Caddyfile 2>/dev/null | head'

echo ''
echo '=== 지금 돌고 있는 설정 (관리 API) ==='
docker exec caddy sh -c 'wget -qO- http://localhost:2019/config/ 2>/dev/null | head -c 400' \
  || curl -s --max-time 10 http://localhost:2019/config/ | head -c 400
echo ''
