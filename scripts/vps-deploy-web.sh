#!/bin/sh
# 고객용 웹앱(index.html)과 비밀번호 재설정 페이지(reset.html)를 massa.moahagwon.com 으로 서빙한다
set -e

DIR=/srv/massa-web
mkdir -p "$DIR"

echo "=== 최신 소스 내려받기 (raw CDN 캐시 우회) ==="
TMP=$(mktemp -d)
curl -s --location codeload.github.com/karmadc070-droid/massa/tar.gz/refs/heads/main -o "$TMP/m.tgz"
tar -xzf "$TMP/m.tgz" -C "$TMP"
cp "$TMP"/massa-main/index.html "$DIR/index.html"
cp "$TMP"/massa-main/reset.html "$DIR/reset.html"
# 결제창을 여는 페이지와 돌아오는 중계 페이지. 앱은 이 두 주소를 앱 내 브라우저로 연다
cp "$TMP"/massa-main/pay-start.html "$DIR/pay-start.html"
cp "$TMP"/massa-main/pay-return.html "$DIR/pay-return.html"
for f in masaage1_b.png wag1_b.png banner1.png banner2.png banner3.png; do
  cp "$TMP"/massa-main/"$f" "$DIR/$f" 2>/dev/null || true
done
rm -rf "$TMP"
ls -la "$DIR"

# 각 페이지가 제대로 받아졌는지 확인한다
grep -q "updateUser" "$DIR/reset.html"        || { echo "reset.html 내용이 이상하다 — 중단"; exit 1; }
grep -q "requestPayment" "$DIR/pay-start.html" || { echo "pay-start.html 내용이 이상하다 — 중단"; exit 1; }
grep -q "toss-payment" "$DIR/pay-return.html"  || { echo "pay-return.html 내용이 이상하다 — 중단"; exit 1; }

echo "=== Caddy 설정 ==="
F=/root/Caddyfile
if grep -q "massa.moahagwon.com" "$F"; then
  echo "이미 등록돼 있음"
else
  cp "$F" "$F.bak.$(date +%s)"
  cat >> "$F" <<'EOF'

massa.moahagwon.com {
    root * /srv/massa-web
    file_server
    encode gzip
    header {
        X-Content-Type-Options "nosniff"
        Referrer-Policy "no-referrer"
    }
}
EOF
  echo "Caddyfile 에 massa.moahagwon.com 추가"
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
sleep 25
curl -s -o /dev/null -w "web   : %{http_code}\n" https://massa.moahagwon.com/ || echo "실패"
curl -s -o /dev/null -w "reset : %{http_code}\n" https://massa.moahagwon.com/reset.html || echo "실패"
curl -s -o /dev/null -w "pay-s : %{http_code}\n" https://massa.moahagwon.com/pay-start.html || echo "실패"
curl -s -o /dev/null -w "pay-r : %{http_code}\n" https://massa.moahagwon.com/pay-return.html || echo "실패"
echo "=== WEB DEPLOY DONE ==="
