#!/bin/sh
# Edge Function 컨테이너는 docker-compose.yml 의 environment: 에 적힌 변수만 받는다.
# .env 에 써도 매핑이 없으면 컨테이너 안에서는 보이지 않는다 (SMTP 때도 같은 함정에 걸렸다).
set -e
CF=/root/massa/docker-compose.yml

if grep -q 'RESEND_KEY: ' "$CF"; then
  echo "이미 매핑돼 있음"
else
  cp "$CF" "$CF.bak.$(date +%s)"
  # functions 서비스의 VERIFY_JWT 줄 바로 뒤에 넣는다 (그 블록 안이 확실하다)
  awk '
    { print }
    /^      VERIFY_JWT: / && !done {
      print "      # 관리자 알림 메일용 — scripts/vps-apply-notify.sh 가 .env 에 값을 넣는다"
      print "      RESEND_KEY: ${RESEND_KEY:-}"
      print "      ADMIN_EMAILS: ${ADMIN_EMAILS:-}"
      print "      NOTIFY_FROM: ${NOTIFY_FROM:-}"
      print "      NOTIFY_SECRET: ${NOTIFY_SECRET:-}"
      done = 1
    }
  ' "$CF" > "$CF.new" && mv "$CF.new" "$CF"
  echo "docker-compose.yml 에 4개 변수 매핑 추가"
fi

echo "=== 재기동 ==="
cd /root/massa && docker compose up -d functions >/dev/null 2>&1
sleep 9

echo "=== 컨테이너 확인 (값은 표시하지 않는다) ==="
docker exec massa-edge-functions sh -c '
  for v in RESEND_KEY NOTIFY_SECRET; do
    eval "x=\$$v"; if [ -n "$x" ]; then echo "  $v 있음 (${#x}자)"; else echo "  ★ $v 없음"; fi
  done
  echo "  ADMIN_EMAILS=$ADMIN_EMAILS"
  echo "  NOTIFY_FROM=$NOTIFY_FROM"
'

echo "=== 발송 시험 ==="
S=$(grep -E '^NOTIFY_SECRET=' /root/massa/.env | cut -d= -f2-)
curl -s -X POST http://localhost:8002/functions/v1/notify-admin \
  -H "Content-Type: application/json" -H "x-notify-secret: $S" \
  -d '{"action":"test"}' | head -c 400
echo
echo "=== 시크릿 없이 호출하면 막히는가 ==="
curl -s -o /dev/null -w "  HTTP %{http_code} (401 이어야 정상)\n" -X POST \
  http://localhost:8002/functions/v1/notify-admin -H "Content-Type: application/json" -d '{"action":"test"}'
echo "=== DONE ==="
