#!/bin/sh
# api.moahagwon.com 을 massa Supabase 게이트웨이(8002)로 연결하고 Caddy를 리로드한다
set -e
F=/root/Caddyfile

if grep -q "api.moahagwon.com" "$F"; then
  echo "=== 이미 등록돼 있음 — Caddyfile 변경 없음 ==="
else
  cp "$F" "$F.bak.$(date +%s)"
  cat >> "$F" <<'EOF'

api.moahagwon.com {
    reverse_proxy localhost:8002
}
EOF
  echo "=== Caddyfile 에 api.moahagwon.com 추가 (백업 생성함) ==="
fi

# 리로드는 무중단. 실패할 때만 재시작으로 넘어간다.
C=$(docker ps --format '{{.Names}}' | grep -i caddy | head -1)
if [ -n "$C" ]; then
  echo "docker caddy: $C"
  docker exec "$C" caddy reload --config /etc/caddy/Caddyfile 2>/dev/null \
    || docker exec "$C" caddy reload --config /root/Caddyfile 2>/dev/null \
    || { echo "reload 실패 — 재시작"; docker restart "$C"; }
else
  systemctl reload caddy 2>/dev/null || systemctl restart caddy
  echo "systemd caddy 리로드"
fi

echo "=== 인증서 발급 대기 ==="
sleep 20

echo "=== 접속 확인 ==="
curl -s -o /dev/null -w "IPv4 : %{http_code}\n" https://api.moahagwon.com/auth/v1/settings || echo "IPv4 실패"
curl -s -6 -o /dev/null -w "IPv6 : %{http_code}\n" https://api.moahagwon.com/auth/v1/settings || echo "IPv6 실패"

echo "=== 기존 도메인도 정상인지 ==="
curl -s -o /dev/null -w "sslip: %{http_code}\n" https://massa.141-164-46-88.sslip.io/auth/v1/settings || echo "sslip 실패"

echo "=== CADDY DONE ==="
