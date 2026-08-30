#!/bin/sh
# 새 테이블·컬럼을 만든 뒤 PostgREST 스키마 캐시를 새로 고친다.
# 이걸 빼먹으면 "Could not find the 'x' column ... in the schema cache" 로 조용히 실패한다
set -e
echo "=== 스키마 리로드 알림 ==="
docker exec massa-db psql -U postgres -d postgres -c "NOTIFY pgrst, 'reload schema';"
sleep 3
echo "=== rest 컨테이너 재시작 ==="
docker restart massa-rest >/dev/null
sleep 8
docker ps --filter name=massa-rest --format '{{.Names}} :: {{.Status}}'
echo "=== SCHEMA RELOAD DONE ==="
