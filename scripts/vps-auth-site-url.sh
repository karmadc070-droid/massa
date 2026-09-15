#!/bin/sh
# 인증 기본 주소(SITE_URL)를 app.massaviet.com 으로 옮긴다.
#
# SITE_URL 은 redirect_to 가 없거나 허용목록 밖일 때 GoTrue 가 보내는 기본 목적지다.
# 지금은 massa.moahagwon.com — 학원 쪽 도메인이라 massa 손님이 거기로 떨어지면 이상하다.
#
# 기존 주소는 허용목록에 그대로 남겨 둔다. 이미 나간 메일의 링크가 살아 있어야 한다.
set -e
ENVF=/root/massa/.env
NEW='https://app.massaviet.com'

echo '=== 이전 ==='
grep -E '^SITE_URL=' "$ENVF" | sed 's/^/  /'

CUR=$(grep -E '^SITE_URL=' "$ENVF" | cut -d= -f2-)
[ "$CUR" = "$NEW" ] && { echo '이미 새 주소다 — 건너뜀'; exit 0; }

# 옛 SITE_URL 이 허용목록에 남아 있는지 먼저 본다. 없으면 바꾸면 안 된다.
ALLOW=$(grep -E '^ADDITIONAL_REDIRECT_URLS=' "$ENVF" | cut -d= -f2-)
case "$ALLOW" in
  *massa.moahagwon.com*) : ;;
  *) echo '★ 옛 주소가 허용목록에 없다 — 바꾸면 기존 메일 링크가 죽는다. 중단'; exit 1 ;;
esac
echo '  옛 주소가 허용목록에 남아 있음 — 안전'

cp "$ENVF" "$ENVF.bak.$(date +%s)"
sed -i "s|^SITE_URL=.*|SITE_URL=$NEW|" "$ENVF"

echo ''
echo '=== 이후 ==='
grep -E '^SITE_URL=' "$ENVF" | sed 's/^/  /'

echo ''
echo '=== auth 다시 띄우기 ==='
cd /root/massa
docker compose up -d auth 2>&1 | tail -2
sleep 8
docker ps --filter name=massa-auth --format '  {{.Names}} {{.Status}}'
docker exec massa-auth sh -c 'echo "  SITE_URL=$GOTRUE_SITE_URL"'

echo ''
echo '=== 판정: 허용목록 밖은 이제 어디로 튕기나 ==='
KEY=$(grep -E '^ANON_KEY=' "$ENVF" | cut -d= -f2-)
LOC=$(curl -s -o /dev/null -D - \
  'https://api.moahagwon.com/auth/v1/verify?token=bogus&type=recovery&redirect_to=https%3A%2F%2Fevil.example.com%2F' \
  -H "apikey: $KEY" | grep -i '^location:' | head -1 | cut -c11- | tr -d '\r')
echo "  $(echo "$LOC" | sed 's/#.*//')"

echo ''
echo '=== 옛 주소는 여전히 살아 있는가 ==='
LOC2=$(curl -s -o /dev/null -D - \
  'https://api.moahagwon.com/auth/v1/verify?token=bogus&type=recovery&redirect_to=https%3A%2F%2Fmassa.moahagwon.com%2Freset.html' \
  -H "apikey: $KEY" | grep -i '^location:' | head -1 | cut -c11- | tr -d '\r')
echo "  $(echo "$LOC2" | sed 's/#.*//')"
