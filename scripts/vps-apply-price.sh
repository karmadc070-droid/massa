#!/bin/sh
# 개인 가격 스키마를 넣고, PostgREST 가 새 함수를 알아보도록 스키마를 다시 읽힌다.
set -e
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < /root/provider_price.sql
echo '--- PostgREST 스키마 다시 읽기 ---'
docker exec -i massa-db psql -U postgres -d postgres -c "notify pgrst, 'reload schema'"
echo '완료'
