#!/bin/bash
# 아이폰 푸시를 붙인다: APNs 키 주입(.env·compose) + send-push 함수 배포 + DB 스키마 + 1분 크론. 비밀 값은 화면에 찍지 않는다.
# 사용: PC 에서 functions/send-push/index.ts 와 scripts/push_schema.sql 을 /tmp/massa-push/ 로 scp 한 뒤 bash 로 실행한다.
set -e
SRC=/tmp/massa-push
cd /root/massa
test -s "$SRC/index.ts" && test -s "$SRC/push_schema.sql" || { echo "$SRC 에 파일이 없다 — 중단"; exit 1; }

echo "=== 1. 백업 ==="
TS=$(date +%Y%m%d-%H%M%S)
cp -p .env ".env.bak-push-$TS"
cp -p docker-compose.yml "docker-compose.yml.bak-push-$TS"
echo "  .env.bak-push-$TS / docker-compose.yml.bak-push-$TS"

echo "=== 2. APNs 키 (.env) — VIBI 와 같은 팀 키를 쓴다 ==="
for K in APPLE_TEAM_ID APNS_KEY_ID APNS_PRIVATE_KEY; do
  if grep -qE "^$K=" .env; then echo "  $K 이미 있음"
  else grep -E "^$K=" /root/vibi/.env >> .env && echo "  $K 추가"; fi
done
chmod 600 .env

echo "=== 3. compose functions 환경변수 ==="
if grep -q 'APNS_KEY_ID: ${APNS_KEY_ID' docker-compose.yml; then echo "  이미 있음"
else
  sed -i 's|^\(\s*\)GOOGLE_MAPS_KEY: ${GOOGLE_MAPS_KEY:-}|&\n\1# 아이폰 푸시(APNs) — scripts/vps-apply-push.sh 가 .env 에 값을 넣는다\n\1APPLE_TEAM_ID: ${APPLE_TEAM_ID:-}\n\1APNS_KEY_ID: ${APNS_KEY_ID:-}\n\1APNS_PRIVATE_KEY: ${APNS_PRIVATE_KEY:-}|' docker-compose.yml
  grep -q 'APNS_KEY_ID: ${APNS_KEY_ID' docker-compose.yml || { echo "  compose 수정 실패 — 중단"; exit 1; }
  echo "  추가함"
fi

echo "=== 4. 함수 배포 ==="
mkdir -p volumes/functions/send-push
cp "$SRC/index.ts" volumes/functions/send-push/index.ts
docker compose up -d functions >/dev/null 2>&1
sleep 8
docker exec massa-edge-functions sh -c 'for k in APPLE_TEAM_ID APNS_KEY_ID APNS_PRIVATE_KEY NOTIFY_SECRET; do eval v=\$$k; [ -n "$v" ] && echo "  컨테이너 $k 있음 (${#v}자)" || echo "  ★ 컨테이너 $k 없음"; done'

echo "=== 5. DB 스키마 ==="
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 -q < "$SRC/push_schema.sql"

echo "=== 6. 1분 크론 (트리거 호출이 빠졌을 때의 안전망) ==="
cat > /root/massa_push.sh <<'EOF'
#!/bin/bash
# massa 푸시 발송 — 안 보낸 알림이 있으면 send-push 가 보낸다(자동 생성됨, scripts/vps-apply-push.sh)
S=$(grep -E '^NOTIFY_SECRET=' /root/massa/.env | cut -d= -f2-)
out=$(curl -s -m 60 -X POST http://localhost:8002/functions/v1/send-push -H "Content-Type: application/json" -H "x-notify-secret: $S" -d '{}')
case "$out" in *'"claimed":0'*) ;; *) echo "$(date -Is) $out" >> /var/log/massa_push.log ;; esac
EOF
chmod 700 /root/massa_push.sh
( crontab -l 2>/dev/null | grep -v massa_push.sh ; echo "* * * * * /bin/bash /root/massa_push.sh" ) | crontab -
crontab -l | grep massa_push.sh | sed 's/^/  /'

echo "=== 7. 호출 확인 (보낼 알림이 없으면 claimed 0) ==="
bash -c 'S=$(grep -E "^NOTIFY_SECRET=" /root/massa/.env | cut -d= -f2-); curl -s -m 60 -X POST http://localhost:8002/functions/v1/send-push -H "x-notify-secret: $S" -d "{}"; echo; curl -s -o /dev/null -w "  시크릿 없이 호출 → %{http_code}\n" -X POST http://localhost:8002/functions/v1/send-push -d "{}"'
echo "=== PUSH DONE ==="
