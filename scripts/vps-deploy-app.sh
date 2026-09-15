#!/bin/sh
# 앱 본체를 app.massaviet.com 으로 배포한다 (Vercel 을 대신한다).
#
# 저장소 루트가 곧 웹앱이다 (index.html · admin.html · sw.js …).
# site/ 는 소개 사이트라 여기서 제외한다 — 그건 vps-deploy-massaviet.sh 가 맡는다.
#
# 옛 주소(massa-seven.vercel.app)는 아직 살려 둔다. 이미 설치된 안드로이드 앱이
# 업데이트를 받기 전까지 그쪽을 보기 때문이다. 여기서는 새 주소만 세운다.
set -e

DIR=/srv/massa-app
REPO=karmadc070-droid/massa

echo '=== 1. 최신 소스 내려받기 ==='
TMP=$(mktemp -d)
curl -s --location "codeload.github.com/$REPO/tar.gz/refs/heads/main" -o "$TMP/m.tgz"
tar -xzf "$TMP/m.tgz" -C "$TMP"
SRC="$TMP/massa-main"
[ -f "$SRC/index.html" ] || { echo '★ index.html 이 없다 — 중단'; rm -rf "$TMP"; exit 1; }

echo '=== 2. 웹앱이 아닌 것 걷어내기 ==='
# 소개 사이트 · 빌드 재료 · 문서 · 열쇠는 웹으로 나가면 안 된다.
rm -rf "$SRC/site" "$SRC/site-src" "$SRC/store-assets" "$SRC/scripts" \
       "$SRC/capacitor" "$SRC/functions" "$SRC/android-package" "$SRC/.github"
rm -f  "$SRC"/*.md "$SRC"/*.xlsx "$SRC"/*.docx "$SRC"/*.csv "$SRC"/vercel.json
rm -f  "$SRC/.env" "$SRC/.gitignore" "$SRC/config.example.js"
find "$SRC" -name '.~lock*' -delete 2>/dev/null || true

echo '=== 3. ★ 비밀이 섞여 있지 않은가 (마지막 빗장) ==='
BAD=$(find "$SRC" -type f \( -name '.env' -o -name '*.keystore' -o -name '*.jks' \
      -o -name '*.p8' -o -name '*.p12' -o -name 'signing-key-info.txt' \) | wc -l)
if [ "$BAD" -gt 0 ]; then
  echo "★ 내보내면 안 되는 파일 ${BAD}개가 남아 있다 — 중단"
  find "$SRC" -type f \( -name '.env' -o -name '*.keystore' -o -name '*.jks' \
       -o -name '*.p8' -o -name '*.p12' -o -name 'signing-key-info.txt' \)
  rm -rf "$TMP"; exit 1
fi
echo '  통과 — 비밀 없음'

echo '=== 4. 배포 ==='
mkdir -p "$DIR"
rm -rf "$DIR"/*  "$DIR"/.well-known
cp -R "$SRC"/. "$DIR"/
rm -rf "$TMP"
echo "  파일 $(find "$DIR" -type f | wc -l)개"
ls -1 "$DIR" | head -12

echo ''
echo '=== 5. Caddy 설정 ==='
F=/root/Caddyfile
if grep -q 'app.massaviet.com' "$F"; then
  echo '  이미 등록돼 있음'
else
  cp "$F" "$F.bak.$(date +%s)"
  cat >> "$F" <<'EOF'

# 앱 본체. Vercel(massa-seven.vercel.app) 을 대신한다.
# cleanUrls: Vercel 이 /foo -> /foo.html 로 열어 줬다. 기존 링크가 깨지지 않게 똑같이 맞춘다.
app.massaviet.com {
    root * /srv/massa-app
    try_files {path} {path}.html {path}/index.html
    file_server
    encode gzip
    header {
        X-Content-Type-Options "nosniff"
        Referrer-Policy "strict-origin-when-cross-origin"
        Permissions-Policy "geolocation=(self)"
    }
    # 서비스워커와 assetlinks 는 캐시되면 갱신이 늦는다. 짧게 잡는다.
    @nocache path /sw.js /manifest.webmanifest /.well-known/*
    header @nocache Cache-Control "no-cache"
}
EOF
  echo '  Caddyfile 에 app.massaviet.com 추가'
fi

C=$(docker ps --format '{{.Names}}' | grep -i caddy | head -1)
if [ -n "$C" ]; then
  docker exec "$C" caddy reload --config /etc/caddy/Caddyfile 2>/dev/null \
    || docker exec "$C" caddy reload --config /root/Caddyfile 2>/dev/null \
    || { echo '  reload 실패 — 재시작'; docker restart "$C"; }
else
  systemctl reload caddy 2>/dev/null || systemctl restart caddy
fi

echo ''
echo '=== 6. 인증서 발급 대기 ==='
sleep 30
for p in "" admin.html sw.js manifest.webmanifest icon-192.png \
         .well-known/assetlinks.json privacy.html terms.html reset.html; do
  printf '%-30s ' "/${p}"
  curl -s -o /dev/null -w '%{http_code}\n' "https://app.massaviet.com/$p"
done

echo ''
echo '=== 7. ★ assetlinks 지문이 그대로인가 (TWA 가 여기 걸린다) ==='
curl -s https://app.massaviet.com/.well-known/assetlinks.json | tr -d ' \n' | head -c 400
echo ''
echo ''
echo '=== 8. ★ 비밀이 웹으로 나가지 않는가 (전부 404 여야 한다) ==='
for p in .env config.example.js android-package/signing.keystore scripts/vps-r2-setup.sh; do
  printf '%-40s ' "/$p"
  curl -s -o /dev/null -w '%{http_code}\n' "https://app.massaviet.com/$p"
done

echo ''
echo '=== APP DEPLOY DONE ==='
