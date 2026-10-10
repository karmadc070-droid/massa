#!/bin/sh
# massaviet.com 소개 사이트를 VPS 에 배포하고 Caddy 로 서빙한다.
# 앱(massa.moahagwon.com)과 완전히 분리된 정적 콘텐츠 사이트다.
set -e

DIR=/srv/massaviet-web
mkdir -p "$DIR"

echo "=== 최신 소스 내려받기 (raw CDN 캐시 우회) ==="
TMP=$(mktemp -d)
curl -s --location codeload.github.com/karmadc070-droid/massa/tar.gz/refs/heads/main -o "$TMP/m.tgz"
tar -xzf "$TMP/m.tgz" -C "$TMP"
# img/ · en/ · vi/ 같은 하위 폴더가 생겼으므로 통째로 복사한다.
# 지워진 파일이 남지 않도록 먼저 비운다 (배포본 = 저장소 상태).
rm -rf "$DIR"/*
cp -R "$TMP"/massa-main/site/. "$DIR"/

# 관리자 화면은 massaviet.com/admin 아래 하나로 모았다 (2026-10-10).
#   /admin/          지표    (site/admin/index.html — build.py 산출물)
#   /admin/console/  운영 콘솔 (admin.html — 빌드를 안 거치는 저장소 루트 파일)
# 이 스크립트가 위에서 docroot 를 통째로 비우므로, 콘솔도 **여기서** 같이 넣어야 한다.
# 다른 스크립트에 맡기면 이 배포가 돌 때마다 콘솔이 사라진다.
mkdir -p "$DIR/admin/console"
cp "$TMP"/massa-main/admin.html "$DIR/admin/console/index.html"
cp "$TMP"/massa-main/reset.html "$DIR/admin/console/reset.html"
# 콘솔이 상대경로로 부르는 그림들. 빠지면 화면이 깨진 채로 돈다.
for f in icon-192.png 11.jpg 22.jpg 33.jpg 44.jpg 55.jpg 66.jpg \
         banner1.png banner2.png banner3.png masaage1_b.png wag1_b.png; do
  cp "$TMP/massa-main/$f" "$DIR/admin/console/$f" 2>/dev/null || echo "  (없음: $f)"
done

rm -rf "$TMP"
ls -la "$DIR"

# 내용이 제대로 받아졌는지 확인한다
grep -q "massaviet.com" "$DIR/sitemap.xml" || { echo "sitemap.xml 이상 — 중단"; exit 1; }
grep -q "출장 마사지" "$DIR/index.html"     || { echo "index.html 이상 — 중단"; exit 1; }
test -s "$DIR/style.css"                    || { echo "style.css 없음 — 중단"; exit 1; }
# 콘솔의 권한 검사가 모듈 스코프 안에 있는지까지 본다 (밖에 있으면 아무나 들어온다)
grep -q "window.guardConsole" "$DIR/admin/console/index.html" \
  || { echo "콘솔 권한 검사 코드가 없다 — 중단"; exit 1; }
G=$(grep -n "async function guardConsole" "$DIR/admin/console/index.html" | cut -d: -f1)
M=$(grep -n '<script type="module">' "$DIR/admin/console/index.html" | cut -d: -f1)
[ "$G" -gt "$M" ] || { echo "guardConsole 이 모듈 밖에 있다 — 중단"; exit 1; }
test -s "$DIR/admin/index.html" || { echo "지표가 없다 — 중단"; exit 1; }

echo "=== Caddy 설정 ==="
F=/root/Caddyfile
if grep -q "massaviet.com" "$F"; then
  echo "이미 등록돼 있음"
else
  cp "$F" "$F.bak.$(date +%s)"
  cat >> "$F" <<'EOF'

# www 는 apex 로 넘긴다. 검색엔진에 같은 내용이 두 주소로 잡히지 않도록.
www.massaviet.com {
    redir https://massaviet.com{uri} permanent
}

massaviet.com {
    root * /srv/massaviet-web
    file_server
    encode gzip
    header {
        X-Content-Type-Options "nosniff"
        Referrer-Policy "strict-origin-when-cross-origin"
        # 정적 사이트라 길게 잡아도 되지만, 초기에는 짧게 두고 나중에 늘린다
        Cache-Control "public, max-age=600"
    }
}
EOF
  echo "Caddyfile 에 massaviet.com 추가"
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
sleep 30
for p in "" download.html services.html guide.html safety.html faq.html partner.html about.html contact.html terms.html privacy.html robots.txt sitemap.xml; do
  printf '%-16s ' "${p:-/}"
  curl -s -o /dev/null -w "%{http_code}\n" "https://massaviet.com/$p" || echo "실패"
done
printf 'www 리다이렉트   '
curl -s -o /dev/null -w "%{http_code} -> %{redirect_url}\n" "https://www.massaviet.com/"
echo "=== MASSAVIET DEPLOY DONE ==="
