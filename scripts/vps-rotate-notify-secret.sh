#!/bin/sh
# 알림 함수의 공유 시크릿을 새로 발급한다. 진단 중 옛 값이 작업 로그에 찍혀서 교체한다.
# 값은 어디에도 출력하지 않는다. 길이만 보여 준다.
set -e
ENV=/root/massa/.env
NEW=$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')

echo "=== 1. .env 교체 ==="
sed -i '/^NOTIFY_SECRET=/d' "$ENV"
echo "NOTIFY_SECRET=$NEW" >> "$ENV"
chmod 600 "$ENV"
echo "  새 시크릿 기록 (${#NEW}자)"

echo "=== 2. DB 설정 교체 (트리거가 쓰는 값) ==="
docker exec massa-db psql -U postgres -d postgres -q -c \
  "update public.app_settings
      set value = jsonb_set(value, '{secret}', to_jsonb('$NEW'::text)), updated_at = now()
    where key='notify';" >/dev/null
echo "  app_settings.notify.secret 갱신"

echo "=== 3. 함수 컨테이너 재기동 ==="
cd /root/massa && docker compose up -d functions >/dev/null 2>&1
sleep 9

echo "=== 4. 새 시크릿으로 발송 (200 이어야 한다) ==="
curl -s -o /dev/null -w "  HTTP %{http_code}\n" -X POST \
  http://localhost:8002/functions/v1/notify-admin \
  -H "Content-Type: application/json" -H "x-notify-secret: $NEW" \
  -d '{"action":"test"}'

echo "=== 5. 옛 시크릿으로 발송 (401 이어야 한다) ==="
curl -s -o /dev/null -w "  HTTP %{http_code}\n" -X POST \
  http://localhost:8002/functions/v1/notify-admin \
  -H "Content-Type: application/json" \
  -H "x-notify-secret: e1c33a4104ae00f55051917b679dc54bdb2687ff4fd86512" \
  -d '{"action":"test"}'

# 매일 아침 요약 스크립트에는 시크릿이 박혀 있다. 여기서 같이 갱신하지 않으면
# 다음 날 아침 다이제스트가 조용히 401 로 실패한다 (한 번 겪었다).
echo "=== 6. 크론 스크립트 갱신 ==="
cat > /root/massa_digest.sh <<EOF
#!/bin/sh
# massa 정산 요약 메일 (vps-rotate-notify-secret.sh 가 생성)
curl -s -X POST http://localhost:8002/functions/v1/notify-admin \\
  -H "Content-Type: application/json" -H "x-notify-secret: $NEW" \\
  -d '{"action":"daily_digest"}' >> /var/log/massa_digest.log 2>&1
echo " <- \$(date -Is)" >> /var/log/massa_digest.log
EOF
chmod 700 /root/massa_digest.sh
sh /root/massa_digest.sh && tail -1 /var/log/massa_digest.log | sed 's/^/  /'

echo "=== ROTATE DONE ==="
