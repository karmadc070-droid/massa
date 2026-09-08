#!/bin/sh
# 합치기 전에 auth 스키마를 백업하고, 실패하면 그대로 멈춘다.
set -e
STAMP=$(date +%Y%m%d_%H%M%S)
echo "=== auth 백업 (/root/auth_backup_$STAMP.sql) ==="
docker exec -i massa-db pg_dump -U postgres -d postgres --schema=auth > "/root/auth_backup_$STAMP.sql"
ls -la "/root/auth_backup_$STAMP.sql"

echo '=== 합치기 ==='
docker exec -i massa-db psql -U postgres -d postgres -v ON_ERROR_STOP=1 < /root/merge_apple_account.sql
