#!/bin/sh
# 진짜로 되는지 본다. 검색 → 후보 → 좌표까지 한 번에.
# 키 값은 찍지 않는다.
set -e
ANON=$(grep -m1 '^ANON_KEY=' /root/massa/.env | cut -d= -f2-)
URL=https://massa.141-164-46-88.sslip.io/functions/v1/places-search

echo '=== 1. 검색 (Lotte Hotel Hanoi) ==='
R=$(curl -s -X POST "$URL" -H "Authorization: Bearer $ANON" -H "apikey: $ANON" \
     -H 'Content-Type: application/json' -d '{"q":"Lotte Hotel Hanoi","lang":"ko","session":"test-1"}')
echo "$R" | head -c 600
echo ''

PID=$(echo "$R" | grep -o '"place_id":"[^"]*"' | head -1 | cut -d'"' -f4)
[ -n "$PID" ] || { echo '★ 후보가 없습니다 — 위 응답을 보세요.'; exit 1; }

echo ''
echo '=== 2. 고른 장소의 좌표 ==='
curl -s -X POST "$URL" -H "Authorization: Bearer $ANON" -H "apikey: $ANON" \
     -H 'Content-Type: application/json' -d "{\"placeId\":\"$PID\",\"lang\":\"ko\",\"session\":\"test-1\"}"
echo ''
echo ''
echo '=== 3. 키 없이 부르면 막히는가 (401 이어야 한다) ==='
curl -s -o /dev/null -w '  HTTP %{http_code}\n' -X POST "$URL" -H 'Content-Type: application/json' -d '{"q":"test"}'
