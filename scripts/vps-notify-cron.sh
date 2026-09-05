#!/bin/sh
# 매일 아침 정산 현황 요약 메일. pg_cron 대신 시스템 crontab 을 쓴다 —
# pg_cron 은 확장 설치와 재기동이 필요한데 얻는 게 없다.
# 처리할 건이 없으면 함수가 알아서 발송을 건너뛴다.
set -e

S=$(grep -E '^NOTIFY_SECRET=' /root/massa/.env | cut -d= -f2-)
test -n "$S" || { echo "NOTIFY_SECRET 이 없다 — vps-apply-notify.sh 를 먼저 돌릴 것"; exit 1; }

cat > /root/massa_digest.sh <<EOF
#!/bin/sh
# massa 정산 요약 메일 (자동 생성됨)
curl -s -X POST http://localhost:8002/functions/v1/notify-admin \\
  -H "Content-Type: application/json" -H "x-notify-secret: $S" \\
  -d '{"action":"daily_digest"}' >> /var/log/massa_digest.log 2>&1
echo " <- \$(date -Is)" >> /var/log/massa_digest.log
EOF
chmod 700 /root/massa_digest.sh

# 하노이 기준 아침에 보게 09:00 KST = 07:00 하노이. 서버는 UTC 라 00:00 UTC.
CRON="0 0 * * * /root/massa_digest.sh"
( crontab -l 2>/dev/null | grep -v massa_digest.sh ; echo "$CRON" ) | crontab -
echo "=== 등록된 크론 ==="
crontab -l | sed 's/^/  /'

echo
echo "=== 지금 한 번 돌려본다 ==="
sh /root/massa_digest.sh
tail -2 /var/log/massa_digest.log | sed 's/^/  /'
echo "=== CRON DONE ==="
