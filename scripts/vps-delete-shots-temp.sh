#!/bin/bash
# 임시로 공개했던 스크린샷을 지운다. 드롭 자동화가 안 돼서 쓸모가 없어졌고,
# 공개 버킷에 남겨 둘 이유도 없다.
set -e
ENVF=/root/massa/.env
KEY=$(grep -E '^SERVICE_ROLE_KEY=' "$ENVF" | cut -d= -f2-)
API=https://api.moahagwon.com
BUCKET=provider-photos

for n in 01-home 02-massage 03-beauty 04-course 05-time 06-place 07-confirm 08-mydash; do
  curl -s -X DELETE "$API/storage/v1/object/$BUCKET/_appstore/$n.png" \
    -H "Authorization: Bearer $KEY" -H "apikey: $KEY" -o /tmp/del.json
  printf '  %-14s %s\n' "$n.png" "$(head -c 60 /tmp/del.json)"
done

echo ''
echo '=== 확인 — 404 여야 한다 ==='
printf '  %s\n' "$(curl -s -o /dev/null -w '%{http_code}' "$API/storage/v1/object/public/$BUCKET/_appstore/01-home.png")"
