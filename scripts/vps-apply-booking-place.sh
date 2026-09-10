#!/bin/sh
# 예약에 좌표 칸을 넣고 PostgREST 에 스키마를 다시 읽힌다.
set -e
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < /root/booking_place.sql
docker exec -i massa-db psql -U postgres -d postgres -c "notify pgrst, 'reload schema'"
echo '완료'
