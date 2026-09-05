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
rm -rf "$TMP"
ls -la "$DIR"

# 내용이 제대로 받아졌는지 확인한다
grep -q "massaviet.com" "$DIR/sitemap.xml" || { echo "sitemap.xml 이상 — 중단"; exit 1; }
grep -q "출장 마사지" "$DIR/index.html"     || { echo "index.html 이상 — 중단"; exit 1; }
test -s "$DIR/style.css"                    || { echo "style.css 없음 — 중단"; exit 1; }

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
