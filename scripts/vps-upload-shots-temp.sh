#!/bin/bash
# 스크린샷을 잠깐 공개 주소에 올린다. App Store Connect 의 '파일 선택' 은
# 네이티브 파일 창(File System Access API)을 띄워서 자동으로 못 고른다.
# 대신 브라우저 안에서 이 주소를 받아 드롭 이벤트로 떨어뜨리려고 올리는 것이다.
# storage 는 CORS 가 열려 있어 다른 사이트(appstoreconnect)에서도 fetch 가 된다.
#
# 올리고 나면 지운다 — vps-delete-shots-temp.sh
set -e
ENVF=/root/massa/.env
KEY=$(grep -E '^SERVICE_ROLE_KEY=' "$ENVF" | cut -d= -f2-)
API=https://api.moahagwon.com
BUCKET=provider-photos

for f in /root/shots-vi/*.png; do
  n=$(basename "$f")
  curl -s -X POST "$API/storage/v1/object/$BUCKET/_appstore/$n" \
    -H "Authorization: Bearer $KEY" -H "apikey: $KEY" \
    -H "Content-Type: image/png" -H "x-upsert: true" \
    --data-binary "@$f" -o /tmp/up.json
  if grep -q '"Key"' /tmp/up.json; then
    printf '  %-16s %s\n' "$n" "$API/storage/v1/object/public/$BUCKET/_appstore/$n"
  else
    printf '  %-16s 실패: %s\n' "$n" "$(head -c 100 /tmp/up.json)"
  fi
done

echo ''
echo '=== 열리는지 + CORS 가 열려 있는지 ==='
U="$API/storage/v1/object/public/$BUCKET/_appstore/01-home.png"
curl -s -o /dev/null -D- --max-time 20 -H 'Origin: https://appstoreconnect.apple.com' "$U" \
  | grep -iE 'HTTP/|access-control-allow-origin|content-type|content-length' | tr -d '\r' | sed 's/^/  /'
