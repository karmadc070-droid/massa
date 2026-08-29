#!/bin/sh
# Caddy 구동 방식과 Caddyfile 위치·내용을 확인한다 (변경 없음, 읽기만)
set -e

echo "=== caddy 컨테이너 ==="
docker ps --format '{{.Names}} | {{.Image}} | {{.Ports}}' | grep -i caddy || echo "(도커에 caddy 없음)"

echo
echo "=== systemd caddy ==="
systemctl is-active caddy 2>/dev/null || echo "(systemd caddy 아님)"

echo
echo "=== Caddyfile 후보 ==="
for f in /root/caddy/Caddyfile /etc/caddy/Caddyfile /root/Caddyfile /root/massa/Caddyfile; do
  [ -f "$f" ] && echo "found: $f"
done
find /root -maxdepth 3 -name Caddyfile 2>/dev/null | head -5

echo
echo "=== massa 도메인이 적힌 파일 ==="
grep -rl "massa.141-164-46-88.sslip.io" /root --include=Caddyfile --include=*.txt --include=*.yml 2>/dev/null | head -5

echo
echo "=== Caddyfile 내용 ==="
F=$(find /root -maxdepth 3 -name Caddyfile 2>/dev/null | head -1)
[ -n "$F" ] && { echo "--- $F ---"; cat "$F"; } || echo "(Caddyfile 못 찾음)"

echo
echo "=== DIAG DONE ==="
