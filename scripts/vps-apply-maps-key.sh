#!/bin/sh
# 지도 키를 .env 에 넣고, 엣지 함수에 전달하도록 붙이고, places-search 를 올린다.
#
# 키 값은 화면에 찍지 않는다. 다 쓰면 /root/maps.key 는 지운다.
# 이미 되어 있으면 다시 하지 않는다 (두 번 돌려도 안전하다).
set -e
CD=/root/massa
ENVF=$CD/.env
DC=$CD/docker-compose.yml

[ -f /root/maps.key ] || { echo '★ /root/maps.key 가 없습니다.'; exit 1; }
KEY=$(tr -d ' \t\r\n' < /root/maps.key)
[ -n "$KEY" ] || { echo '★ 키가 비어 있습니다.'; exit 1; }
echo "키 길이: ${#KEY}"

echo ''
echo '=== 1. .env 에 넣기 ==='
sed -i '/^GOOGLE_MAPS_KEY=/d' "$ENVF"
printf 'GOOGLE_MAPS_KEY=%s\n' "$KEY" >> "$ENVF"
grep -c '^GOOGLE_MAPS_KEY=' "$ENVF" | sed 's/^/  .env 줄 수: /'

echo ''
echo '=== 2. docker-compose 에 전달 줄 붙이기 ==='
if grep -q 'GOOGLE_MAPS_KEY: ' "$DC"; then
  echo '  이미 있음 — 건너뜀'
else
  cp "$DC" "$DC.bak-maps"
  sed -i 's|^      NOTIFY_SECRET: ${NOTIFY_SECRET:-}$|      NOTIFY_SECRET: ${NOTIFY_SECRET:-}\n      # 숙소 검색용 구글 지도 키 — scripts/vps-apply-maps-key.sh 가 .env 에 값을 넣는다\n      GOOGLE_MAPS_KEY: ${GOOGLE_MAPS_KEY:-}|' "$DC"
  grep -n 'GOOGLE_MAPS_KEY' "$DC" | sed 's/^/  /'
fi

echo ''
echo '=== 3. places-search 함수 확인 ==='
ls -la "$CD/volumes/functions/places-search/index.ts" | sed 's/^/  /'

echo ''
echo '=== 4. 엣지 함수 다시 띄우기 ==='
cd "$CD"
docker compose up -d functions 2>&1 | tail -3
sleep 6
docker ps --filter name=massa-edge-functions --format '  {{.Names}} {{.Status}}'

echo ''
echo '=== 5. 컨테이너 안에 키가 들어갔는가 (길이만) ==='
docker exec massa-edge-functions sh -c 'printf "  GOOGLE_MAPS_KEY 길이: %s\n" "${#GOOGLE_MAPS_KEY}"'

shred -u /root/maps.key 2>/dev/null || rm -f /root/maps.key
echo ''
echo '키 파일 삭제됨'
