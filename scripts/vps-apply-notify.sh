#!/bin/sh
# 관리자 알림 메일을 붙인다: Edge Function 배포 + 시크릿 주입 + DB 트리거.
# Resend 키는 /root/resend.key 에서 읽어 화면에 찍지 않는다.
set -e

ADMIN_EMAILS="karmadc070@gmail.com,moahagwon@gmail.com"
ENV=/root/massa/.env

test -s /root/resend.key || { echo "/root/resend.key 가 없다 — 중단"; exit 1; }
RK=$(tr -d '\r\n' < /root/resend.key)

echo "=== 1. 소스 내려받기 ==="
TMP=$(mktemp -d)
curl -s --location codeload.github.com/karmadc070-droid/massa/tar.gz/refs/heads/main -o "$TMP/m.tgz"
tar -xzf "$TMP/m.tgz" -C "$TMP"
SRC="$TMP/massa-main/functions/notify-admin/index.ts"
test -s "$SRC" || { echo "함수 소스를 못 받았다 — 중단"; exit 1; }

DST=/root/massa/volumes/functions/notify-admin
mkdir -p "$DST"
cp "$SRC" "$DST/index.ts"
echo "  $DST/index.ts ($(wc -c < "$DST/index.ts") bytes)"

echo "=== 2. 시크릿 주입 (.env) ==="
# 이미 있으면 지우고 다시 넣는다. 값은 출력하지 않는다.
SECRET=$(grep -E '^NOTIFY_SECRET=' "$ENV" 2>/dev/null | cut -d= -f2-)
if [ -z "$SECRET" ]; then SECRET=$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n'); fi
sed -i '/^RESEND_KEY=/d;/^ADMIN_EMAILS=/d;/^NOTIFY_FROM=/d;/^NOTIFY_SECRET=/d' "$ENV"
{
  echo "RESEND_KEY=$RK"
  echo "ADMIN_EMAILS=$ADMIN_EMAILS"
  echo "NOTIFY_FROM=massa <massa@moahagwon.com>"
  echo "NOTIFY_SECRET=$SECRET"
} >> "$ENV"
chmod 600 "$ENV"
echo "  RESEND_KEY / ADMIN_EMAILS / NOTIFY_FROM / NOTIFY_SECRET 기록 (값은 표시하지 않음)"
echo "  받는 사람: $ADMIN_EMAILS"

echo "=== 3. 함수 컨테이너에 반영 ==="
cd /root/massa && docker compose up -d functions >/dev/null 2>&1 || docker restart massa-edge-functions >/dev/null
sleep 8
docker exec massa-edge-functions sh -c 'test -n "$RESEND_KEY" && echo "  컨테이너에 RESEND_KEY 있음" || echo "  ★ 컨테이너에 RESEND_KEY 없음"'
docker exec massa-edge-functions sh -c 'echo "  ADMIN_EMAILS=$ADMIN_EMAILS"'

echo "=== 4. DB 트리거 ==="
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < "$TMP/massa-main/scripts/notify_trigger.sql"
# 트리거가 쓸 시크릿을 설정 테이블에 넣는다 (관리자만 읽는 테이블이다)
docker exec massa-db psql -U postgres -d postgres -q -c \
  "update public.app_settings set value = jsonb_build_object(
     'url','http://massa-edge-functions:9000/notify-admin','secret','$SECRET'), updated_at=now()
   where key='notify';" >/dev/null
echo "  트리거 등록 + 설정 반영"
rm -rf "$TMP"

echo "=== 5. 발송 시험 ==="
curl -s -X POST http://localhost:8002/functions/v1/notify-admin \
  -H "Content-Type: application/json" -H "x-notify-secret: $SECRET" \
  -d '{"action":"test"}' | head -c 400
echo
echo "=== NOTIFY DONE ==="
