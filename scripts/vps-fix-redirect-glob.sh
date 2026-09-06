#!/bin/sh
# GoTrue 의 허용 목록 글롭에서 `*` 는 경로 구분자 `/` 를 넘지 못한다.
# 그래서 `https://massaviet.com/*` 는 `https://massaviet.com/admin/` 에 걸리지 않았고,
# GoTrue 가 referer(=사이트 루트)로 되돌려 보내면서 토큰이 루트 주소에 붙어 버렸다.
# 여러 단계 경로까지 덮으려면 `**` 를 써야 한다.
set -e
ENV=/root/massa/.env
CUR=$(grep -E '^ADDITIONAL_REDIRECT_URLS=' "$ENV" | cut -d= -f2-)
echo "=== 현재 ==="; echo "  $CUR"

case "$CUR" in
  *'massaviet.com/**'*) echo "  이미 ** 가 있음";;
  *) NEW="$CUR,https://massaviet.com/**"
     sed -i "s|^ADDITIONAL_REDIRECT_URLS=.*|ADDITIONAL_REDIRECT_URLS=$NEW|" "$ENV"
     echo "=== 추가 후 ==="; grep -E '^ADDITIONAL_REDIRECT_URLS=' "$ENV" | sed 's/^/  /';;
esac

echo "=== auth 재기동 ==="
cd /root/massa && docker compose up -d auth >/dev/null 2>&1 || docker restart massa-auth >/dev/null
sleep 8
docker exec massa-auth env | grep GOTRUE_URI_ALLOW_LIST | sed 's/^/  /'
echo "=== FIX DONE ==="
