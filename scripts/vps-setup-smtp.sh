#!/bin/sh
# GoTrue(auth) 의 메일 발송을 Resend SMTP 로 바꾼다.
# 사전 준비: Resend API 키를 /root/resend.key 에 한 줄로 저장해 둘 것 (noVNC 클립보드로 붙여넣기).
set -e

ENV=/root/massa/.env
KEYFILE=/root/resend.key
SENDER="massa@moahagwon.com"
SITE="https://massa.moahagwon.com"

[ -f "$KEYFILE" ] || { echo "$KEYFILE 이 없다. Resend API 키를 저장한 뒤 다시 실행할 것"; exit 1; }
KEY=$(tr -d ' \t\r\n' < "$KEYFILE")
[ -n "$KEY" ] || { echo "$KEYFILE 이 비어 있다"; exit 1; }
case "$KEY" in re_*) ;; *) echo "키가 re_ 로 시작하지 않는다 — 잘못 붙여넣은 듯"; exit 1 ;; esac

cp "$ENV" "$ENV.bak.$(date +%s)"

# 기존 값을 지우고 새로 넣는다 (중복 키가 생기면 뒤엣것이 이기므로 먼저 지운다)
sed -i '/^SMTP_ADMIN_EMAIL=/d;/^SMTP_HOST=/d;/^SMTP_PORT=/d;/^SMTP_USER=/d;/^SMTP_PASS=/d;/^SMTP_SENDER_NAME=/d;/^GOTRUE_SITE_URL=/d;/^GOTRUE_URI_ALLOW_LIST=/d;/^GOTRUE_MAILER_AUTOCONFIRM=/d;/^API_EXTERNAL_URL=/d' "$ENV"

cat >> "$ENV" <<EOF
SMTP_ADMIN_EMAIL=$SENDER
SMTP_HOST=smtp.resend.com
SMTP_PORT=587
SMTP_USER=resend
SMTP_PASS=$KEY
SMTP_SENDER_NAME=massa
GOTRUE_SITE_URL=$SITE
GOTRUE_URI_ALLOW_LIST=$SITE/*,$SITE/reset.html,https://admin.moahagwon.com/*
GOTRUE_MAILER_AUTOCONFIRM=true
API_EXTERNAL_URL=https://api.moahagwon.com
EOF

echo "=== 반영된 값 (비밀번호는 가림) ==="
grep -E "^(SMTP_|GOTRUE_SITE_URL|GOTRUE_URI_ALLOW_LIST|GOTRUE_MAILER_AUTOCONFIRM|API_EXTERNAL_URL)" "$ENV" | sed 's/^SMTP_PASS=.*/SMTP_PASS=***가림***/'

echo
echo "=== auth 컨테이너 재생성 ==="
cd /root/massa
docker compose up -d auth

sleep 8
A=$(docker ps --format '{{.Names}}' | grep massa | grep -i auth | head -1)
echo "container: $A"
docker exec "$A" env | grep -E "SMTP_HOST|SMTP_PORT|SMTP_USER|SITE_URL|URI_ALLOW" || true

echo
echo "=== 헬스 체크 ==="
curl -s -o /dev/null -w "auth settings: %{http_code}\n" https://api.moahagwon.com/auth/v1/settings
echo "=== SMTP SETUP DONE ==="
