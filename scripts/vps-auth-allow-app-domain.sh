#!/bin/sh
# 로그인이 app.massaviet.com 으로 돌아올 수 있게 GoTrue 허용목록에 새 주소를 넣는다.
#
# 허용목록에 없는 주소로 돌아오라고 하면 GoTrue 는 조용히 SITE_URL 로 보낸다.
# 에러가 안 나고 '엉뚱한 주소로 로그인됨' 으로 나타나서 알아채기 어렵다. 그래서 먼저 넣는다.
#
# 기존 주소는 하나도 빼지 않는다. massa.moahagwon.com 은 아직 살아 있어야 한다.
set -e
ENVF=/root/massa/.env
ADD='https://app.massaviet.com/*,https://app.massaviet.com/**'

echo '=== 이전 ==='
grep -E '^ADDITIONAL_REDIRECT_URLS=' "$ENVF" | sed 's/^/  /'

CUR=$(grep -E '^ADDITIONAL_REDIRECT_URLS=' "$ENVF" | cut -d= -f2-)
case "$CUR" in
  *app.massaviet.com*) echo '이미 들어 있음 — 건너뜀'; exit 0 ;;
esac

cp "$ENVF" "$ENVF.bak.$(date +%s)"
NEW="$CUR,$ADD"
# 값에 / 가 들어가므로 구분자를 | 로 쓴다
sed -i "s|^ADDITIONAL_REDIRECT_URLS=.*|ADDITIONAL_REDIRECT_URLS=$NEW|" "$ENVF"

echo ''
echo '=== 이후 ==='
grep -E '^ADDITIONAL_REDIRECT_URLS=' "$ENVF" | sed 's/^/  /'

echo ''
echo '=== auth 다시 띄우기 ==='
cd /root/massa
docker compose up -d auth 2>&1 | tail -3
sleep 8
docker ps --filter name=massa-auth --format '  {{.Names}} {{.Status}}'

echo ''
echo '=== 컨테이너에 실제로 들어갔는가 ==='
docker exec massa-auth sh -c 'echo "  $GOTRUE_URI_ALLOW_LIST"'

echo ''
echo '=== 인증 서버가 살아 있는가 (401 이면 정상 — 토큰 없이 물었으니) ==='
printf '  health: '; curl -s -o /dev/null -w '%{http_code}\n' https://massa.141-164-46-88.sslip.io/auth/v1/health
