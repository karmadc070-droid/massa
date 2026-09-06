#!/bin/sh
# 관리자 지표 화면이 massaviet.com 에 있으므로, 구글 로그인·비밀번호 재설정이
# 그 주소로 돌아올 수 있어야 한다. 허용 목록에 없으면 GoTrue 가 SITE_URL 로 되돌려 버린다.
set -e
ENV=/root/massa/.env
WANT='https://massaviet.com/*'

CUR=$(grep -E '^ADDITIONAL_REDIRECT_URLS=' "$ENV" | cut -d= -f2-)
echo "=== 현재 ==="
echo "  $CUR"

case "$CUR" in
  *"massaviet.com"*) echo "  이미 들어 있음";;
  *) sed -i "s|^ADDITIONAL_REDIRECT_URLS=.*|ADDITIONAL_REDIRECT_URLS=$CUR,$WANT|" "$ENV"
     echo "=== 추가 후 ==="
     grep -E '^ADDITIONAL_REDIRECT_URLS=' "$ENV" | sed 's/^/  /';;
esac

echo "=== auth 재기동 ==="
cd /root/massa && docker compose up -d auth >/dev/null 2>&1 || docker restart massa-auth >/dev/null
sleep 8
docker exec massa-auth env | grep GOTRUE_URI_ALLOW_LIST | sed 's/^/  /'

echo "=== 로그인 엔드포인트 확인 (302 면 정상) ==="
curl -s -o /dev/null -w "  google  HTTP %{http_code}\n" \
  "https://api.moahagwon.com/auth/v1/authorize?provider=google&redirect_to=https%3A%2F%2Fmassaviet.com%2Fadmin%2F"
echo "=== ALLOW LIST DONE ==="
