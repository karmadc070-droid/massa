#!/bin/sh
# ⛔ 더 쓰지 않는다 (2026-10-10). 관리자 화면은 massaviet.com/admin 아래로 모았다.
#
#   지표      massaviet.com/admin/
#   운영 콘솔 massaviet.com/admin/console/
#   둘 다 scripts/vps-deploy-massaviet.sh 가 배포한다.
#
# 이 스크립트가 쓰던 /srv/massa-admin 은 이제 Caddy 가 서빙하지 않는다.
# 돌려 봐야 아무도 안 보는 자리에 파일만 쌓인다. 기록으로 남겨 둘 뿐이다.
echo "이 스크립트는 더 쓰지 않습니다. scripts/vps-deploy-massaviet.sh 를 쓰세요."
echo "  지표      https://massaviet.com/admin/"
echo "  운영 콘솔 https://massaviet.com/admin/console/"
exit 1

# ─── 아래는 옛 내용 (참고용) ───────────────────────────────
# 운영 콘솔(admin.html)을 /srv/massa-admin 에 배포하고 admin.massaviet.com 으로 서빙한다
# (2026-10-01 이전. 옛 주소 admin.moahagwon.com 은 301 로 살려 둔다)
set -e

DIR=/srv/massa-admin
mkdir -p "$DIR"

echo "=== admin.html 내려받기 (raw CDN 캐시 우회) ==="
# raw.githubusercontent.com 은 최대 5분 캐시된다. codeload 는 항상 최신 커밋을 준다.
TMP=$(mktemp -d)
curl -s --location codeload.github.com/karmadc070-droid/massa/tar.gz/refs/heads/main -o "$TMP/m.tgz"
tar -xzf "$TMP/m.tgz" -C "$TMP"
cp "$TMP"/massa-main/admin.html "$DIR/index.html"
# 비밀번호 재설정 페이지도 같이 올린다.
# 2026-10-05: 이게 빠져 있어서 admin.massaviet.com/reset.html 이 404 였고,
# 콘솔의 재설정 메일 링크가 죽어 있었다. 콘솔 재설정은 콘솔 도메인에서 끝나야 한다.
cp "$TMP"/massa-main/reset.html "$DIR/reset.html"
# 지표는 massaviet.com/admin 하나로 모았다 (2026-10-10).
# 여기 있던 /metrics/ 사본은 지운다. 안 지우면 Caddy 가 리다이렉트를 걷는 날 되살아난다.
rm -rf "$DIR/metrics"
rm -rf "$TMP"
ls -la "$DIR/index.html" "$DIR/reset.html"

# 권한 검사 코드가 모듈 스코프에 있는지까지 확인한다
grep -q "window.guardConsole" "$DIR/index.html" || { echo "권한 검사 코드가 없다 — 중단"; exit 1; }
GUARD_LINE=$(grep -n "async function guardConsole" "$DIR/index.html" | cut -d: -f1)
MODULE_LINE=$(grep -n '<script type="module">' "$DIR/index.html" | cut -d: -f1)
echo "guardConsole=$GUARD_LINE / module 시작=$MODULE_LINE"
[ "$GUARD_LINE" -gt "$MODULE_LINE" ] || { echo "guardConsole 이 모듈 밖에 있다 — 중단"; exit 1; }

echo "=== 이미지·아이콘 복사 (앱과 동일 자산) ==="
for f in masaage1_b.png wag1_b.png banner1.png banner2.png banner3.png; do
  curl -s --location "raw.githubusercontent.com/karmadc070-droid/massa/main/$f" -o "$DIR/$f" || true
done

echo "=== Caddy 설정 ==="
# 2026-10-01 운영 콘솔 주소가 admin.moahagwon.com → admin.massaviet.com 으로 바뀌었다.
# 옛 주소는 지우지 않고 새 주소로 301 리다이렉트만 한다(북마크·예전 메일 링크 보호).
F=/root/Caddyfile
if grep -q "admin.massaviet.com" "$F"; then
  echo "이미 등록돼 있음"
else
  cp "$F" "$F.bak.$(date +%s)"
  cat >> "$F" <<'EOF'

admin.massaviet.com {
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
  echo "Caddyfile 에 admin.massaviet.com 추가"
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
curl -s -o /dev/null -w "admin     : %{http_code}\n" https://admin.massaviet.com/ || echo "실패"
curl -s -o /dev/null -w "reset     : %{http_code} (200 이어야 한다)\n" https://admin.massaviet.com/reset.html || echo "실패"
curl -s -o /dev/null -w "옛 지표   : %{http_code} (301 이어야 한다)\n" https://admin.massaviet.com/metrics/ || echo "실패"
curl -s -o /dev/null -w "지표      : %{http_code} (200 이어야 한다)\n" https://massaviet.com/admin/ || echo "실패"
curl -s -o /dev/null -w "옛 주소   : %{http_code} (301 이어야 한다)\n" https://admin.moahagwon.com/ || echo "실패"
curl -s -o /dev/null -w "api   : %{http_code}\n" https://api.moahagwon.com/auth/v1/settings || echo "실패"
echo "=== DEPLOY DONE ==="
