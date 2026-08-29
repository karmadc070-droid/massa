#!/bin/sh
# 운영 콘솔(admin.html)을 /srv/massa-admin 에 배포하고 admin.moahagwon.com 으로 서빙한다
set -e

DIR=/srv/massa-admin
mkdir -p "$DIR"

echo "=== admin.html 내려받기 ==="
curl -s --location raw.githubusercontent.com/karmadc070-droid/massa/main/admin.html -o "$DIR/index.html"
ls -la "$DIR/index.html"
grep -c "guardConsole" "$DIR/index.html" || { echo "권한 검사 코드가 없다 — 중단"; exit 1; }

echo "=== 이미지·아이콘 복사 (앱과 동일 자산) ==="
for f in masaage1_b.png wag1_b.png banner1.png banner2.png banner3.png; do
  curl -s --location "raw.githubusercontent.com/karmadc070-droid/massa/main/$f" -o "$DIR/$f" || true
done

echo "=== Caddy 설정 ==="
F=/root/Caddyfile
if grep -q "admin.moahagwon.com" "$F"; then
  echo "이미 등록돼 있음"
else
  cp "$F" "$F.bak.$(date +%s)"
  cat >> "$F" <<'EOF'

admin.moahagwon.com {
    root * /srv/massa-admin
    file_server
    encode gzip
    header {
        X-Frame-Options "DENY"
        X-Content-Type-Options "nosniff"
        Referrer-Policy "no-referrer"
        X-Robots-Tag "noindex, nofollow"
    }
}
EOF
  echo "Caddyfile 에 admin.moahagwon.com 추가"
fi

C=$(docker ps --format '{{.Names}}' | grep -i caddy | head -1)
if [ -n "$C" ]; then
  docker exec "$C" caddy reload --config /etc/caddy/Caddyfile 2>/dev/null \
    || docker exec "$C" caddy reload --config /root/Caddyfile 2>/dev/null \
    || { echo "reload 실패 — 재시작"; docker restart "$C"; }
else
  systemctl reload caddy 2>/dev/null || systemctl restart caddy
fi

echo "=== 인증서 발급 대기 ==="
sleep 20
curl -s -o /dev/null -w "admin : %{http_code}\n" https://admin.moahagwon.com/ || echo "실패"
curl -s -o /dev/null -w "api   : %{http_code}\n" https://api.moahagwon.com/auth/v1/settings || echo "실패"
echo "=== DEPLOY DONE ==="
