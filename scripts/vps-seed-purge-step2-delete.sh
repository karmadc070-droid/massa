#!/bin/bash
# 시드 예약 8건과 시드 후기 9건을 지운다. 사장님 승인 후 실행.
#
# 지우기 전에 반드시 백업한다. 되돌릴 수 없는 작업에서 '아차' 는 한 번이면 끝이다.
# reviews.booking_id 는 CASCADE 라 예약을 지우면 후기도 딸려 간다 —
# 그래도 후기를 먼저 명시적으로 지운다. 어느 쪽이 몇 건을 지웠는지 숫자로 보기 위해서다.
set -e

TS=$(date +%Y%m%d-%H%M%S)
OUT=/root/backups/seed-purge-$TS
mkdir -p "$OUT"
SQL() { docker exec -i massa-db psql -U postgres -d postgres "$@" < /dev/null; }
DUMP() { docker exec -i massa-db psql -U postgres -d postgres -c "\copy ($1) to stdout with csv header" < /dev/null > "$OUT/$2"; }

echo "=== 0. 안전장치 — 날짜가 불가능한(시드) 예약만 대상인지 다시 확인 ==="
SQL -c "select count(*) as total, count(*) filter (where scheduled_at < created_at) as impossible from bookings;"
BAD=$(docker exec -i massa-db psql -U postgres -d postgres -tAc \
  "select count(*) from bookings where scheduled_at >= created_at;" < /dev/null | tr -d ' ')
if [ "$BAD" != "0" ]; then
  echo "★ 날짜가 정상인 예약이 $BAD 건 있다 — 진짜 예약일 수 있으므로 중단한다."
  exit 1
fi
echo "  통과 — 전부 시드다"

echo ''
echo "=== 1. 백업 ($OUT) ==="
DUMP "select * from bookings" bookings.csv
DUMP "select * from reviews" reviews.csv
DUMP "select * from payment_transactions" payment_transactions.csv
DUMP "select * from safety_alerts" safety_alerts.csv
DUMP "select * from messages" messages.csv
ls -la "$OUT"

echo ''
echo "=== 2. 지우기 (한 트랜잭션) ==="
docker exec -i massa-db psql -U postgres -d postgres <<'PY'
begin;
with d as (delete from reviews returning 1) select count(*) as reviews_deleted from d;
with d as (delete from bookings returning 1) select count(*) as bookings_deleted from d;
commit;
PY

echo ''
echo "=== 3. 확인 ==="
SQL -c "
select (select count(*) from bookings) as bookings_left,
       (select count(*) from reviews)  as reviews_left,
       (select count(*) from payment_transactions where booking_id is null) as pay_tx_orphaned,
       (select count(*) from safety_alerts where booking_id is null) as alerts_orphaned,
       (select count(*) from messages) as messages_left;"

echo ''
echo "=== 4. 마사지사 카드에 남은 별점·후기 수 (0 이어야 한다) ==="
SQL -c "
select count(*) filter (where review_count > 0) as cards_with_review_count,
       count(*) filter (where rating > 0) as cards_with_rating
from providers where is_active and application_status='approved';"

echo ''
echo "백업 위치: $OUT"
