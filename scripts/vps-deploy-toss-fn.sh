#!/bin/sh
# toss-payment Edge Function 을 VPS 에 배포하고 컨테이너를 다시 올린다
set -e

echo "=== 최신 소스 받기 ==="
rm -rf /tmp/massa-main /tmp/m.tgz
curl -sL codeload.github.com/karmadc070-droid/massa/tar.gz/refs/heads/main -o /tmp/m.tgz
tar -xzf /tmp/m.tgz -C /tmp

SRC=/tmp/massa-main/functions/toss-payment/index.ts
DST=/root/massa/volumes/functions/toss-payment

[ -f "$SRC" ] || { echo "소스가 없다: $SRC"; exit 1; }

mkdir -p "$DST"
cp "$SRC" "$DST/index.ts"
echo "=== 배포됨 ==="
ls -la "$DST"
grep -c "toss" "$DST/index.ts" | sed 's/^/toss 언급 줄수: /'

echo
echo "=== functions 컨테이너 재시작 ==="
docker restart massa-edge-functions >/dev/null
sleep 6
docker ps --filter name=massa-edge-functions --format '{{.Names}} :: {{.Status}}'

echo
echo "=== 호출 테스트 (인증 없이 → 401 이 정상) ==="
curl -s -o /dev/null -w "toss-payment: %{http_code}\n" \
  -X POST https://api.moahagwon.com/functions/v1/toss-payment \
  -H "Content-Type: application/json" -d '{"action":"create"}'

echo
echo "=== 로그 ==="
docker logs --tail 8 massa-edge-functions 2>&1

echo
echo "=== TOSS FN DEPLOY DONE ==="
