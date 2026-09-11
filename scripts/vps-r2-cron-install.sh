#!/bin/sh
# 업로드를 크론에 붙이고 한 번 돌려 본다.
set -e
chmod +x /root/backup_upload_r2.sh

echo '=== 한 번 실행 ==='
/bin/bash /root/backup_upload_r2.sh
tail -3 /root/backups/upload.log

echo ''
echo '=== 크론 등록 (03:10 백업 → 03:25 잠금 → 03:40 업로드) ==='
CR=$(mktemp)
crontab -l 2>/dev/null | grep -v 'backup_upload_r2.sh' > "$CR" || true
echo '40 3 * * * /bin/bash /root/backup_upload_r2.sh' >> "$CR"
crontab "$CR"
rm -f "$CR"
crontab -l | grep -v '^#' | grep -v '^$'

echo ''
echo '=== 최종 상태 ==='
echo "서버 평문 : $(ls -1 /root/backups/*.sql.gz 2>/dev/null | wc -l)개 (7일)"
echo "서버 잠김 : $(ls -1 /root/backups/enc/*.gpg 2>/dev/null | wc -l)개 (7일)"
echo "R2 원격   : $(rclone ls r2:massa-db-backup/enc 2>/dev/null | wc -l)개 (30일)"
