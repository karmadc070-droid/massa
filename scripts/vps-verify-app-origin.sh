#!/bin/sh
# 새 주소 배포본이 제대로 갈아끼워졌는지 본다.
echo '=== 결제 페이지가 새 주소에 있는가 ==='
for p in pay-start.html pay-return.html reset.html delete-account.html; do
  printf '  %-22s ' "$p"
  curl -s -o /dev/null -w '%{http_code}\n' "https://app.massaviet.com/$p"
done

echo ''
echo '=== 배포본 index.html 이 가리키는 주소 ==='
grep -oE "https://[a-z.-]+/(reset|pay-start)\.html" /srv/massa-app/index.html | sort -u | sed 's/^/  /'

echo ''
echo '=== 옛 주소(moahagwon)가 손님 화면에 남아 있는가 ==='
N=$(grep -c 'massa\.moahagwon\.com' /srv/massa-app/index.html || true)
echo "  index.html 안의 massa.moahagwon.com: ${N}건 (0 이어야 한다)"

echo ''
echo '=== 인증 허용목록 최종 ==='
docker exec massa-auth sh -c 'echo "  $GOTRUE_URI_ALLOW_LIST"' | tr ',' '\n' | sed 's/^/  /'
