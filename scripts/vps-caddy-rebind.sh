#!/bin/bash
# Caddy 컨테이너가 /root/Caddyfile 의 '옛 inode' 를 붙들고 있어서, 호스트에서 고쳐도
# 컨테이너 안에서는 안 바뀐다. 단일 파일 바인드 마운트에서 파일이 통째로 새로 써지면
# 생기는 흔한 문제다.
#
# 컨테이너를 다시 만들지 않고 고치는 방법 — 지금 마운트돼 있는 그 파일에 직접 써 넣는다.
# docker cp 는 컨테이너 쪽 경로에 쓰므로 마운트된 inode 를 그대로 덮어쓴다.
set -e

echo '=== 전 ==='
printf '  host      inode=%s\n' "$(stat -c %i /root/Caddyfile)"
printf '  container inode=%s\n' "$(docker exec caddy stat -c %i /etc/caddy/Caddyfile)"
printf '  리다이렉트 들어있나 — host=%s container=%s\n' \
  "$(grep -c 'massa-old-retired' /root/Caddyfile)" \
  "$(docker exec caddy grep -c 'massa-old-retired' /etc/caddy/Caddyfile || echo 0)"

echo ''
echo '=== 컨테이너가 보는 파일로 복사 ==='
docker cp /root/Caddyfile caddy:/etc/caddy/Caddyfile
printf '  복사 후 container 안에 리다이렉트: %s\n' \
  "$(docker exec caddy grep -c 'massa-old-retired' /etc/caddy/Caddyfile)"

echo ''
echo '=== 문법 검사 ==='
docker exec caddy caddy validate --config /etc/caddy/Caddyfile 2>&1 | tail -2

echo ''
echo '=== reload ==='
docker exec caddy caddy reload --config /etc/caddy/Caddyfile 2>&1 | tail -2
sleep 5

echo ''
echo '=== 확인 ==='
for u in https://massa.moahagwon.com/ https://massa.moahagwon.com/privacy.html; do
  printf '  %-44s %s -> %s\n' "$u" \
    "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$u")" \
    "$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 20 "$u")"
done
echo '  -- 나머지가 멀쩡한지 --'
for u in https://app.massaviet.com/ https://admin.massaviet.com/ https://massaviet.com/ \
         https://app.massaviet.com/.well-known/assetlinks.json; do
  printf '  %-52s %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$u")"
done
printf '  %-52s %s  (401 이 정상)\n' 'https://api.moahagwon.com/auth/v1/health' \
  "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://api.moahagwon.com/auth/v1/health)"
