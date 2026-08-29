#!/bin/sh
# massa 스택의 메일(SMTP) 설정 상태를 확인한다 (비밀값은 가린다)
set -e
ENV=/root/massa/.env

echo "=== .env 의 메일 관련 설정 ==="
if [ -f "$ENV" ]; then
  grep -i "smtp\|mailer\|SITE_URL\|URI_ALLOW" "$ENV" | sed 's/\(PASS[^=]*=\).*/\1***가림***/I' || echo "(메일 설정 없음)"
else
  echo "$ENV 없음"
fi

echo
echo "=== auth 컨테이너에 적용된 값 ==="
A=$(docker ps --format '{{.Names}}' | grep massa | grep -i auth | head -1)
echo "container: $A"
[ -n "$A" ] && docker exec "$A" env | grep -i "smtp\|mailer_autoconfirm\|SITE_URL\|URI_ALLOW" | sed 's/\(PASS[^=]*=\).*/\1***가림***/I'

echo
echo "=== SMTP CHECK DONE ==="
