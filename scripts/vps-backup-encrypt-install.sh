#!/bin/sh
# 암호화 단계를 크론에 붙이고, 지금 있는 백업을 한 번 잠가 본다.
set -e
chmod +x /root/pg_backup_encrypt.sh

echo '=== 지금 있는 백업 잠그기 ==='
sh /root/pg_backup_encrypt.sh
tail -3 /root/backups/encrypt.log

echo ''
echo '=== 결과 ==='
ls -1 /root/backups/enc/*.gpg 2>/dev/null | wc -l | sed 's/^/잠긴 파일: /'
du -sh /root/backups/enc 2>/dev/null
ls -lt /root/backups/enc/massa-db_*.gpg 2>/dev/null | head -3

echo ''
echo '=== 크론 등록 (03:10 백업 뒤 03:25 에 잠근다) ==='
CR=$(mktemp)
crontab -l 2>/dev/null | grep -v 'pg_backup_encrypt.sh' > "$CR" || true
echo '25 3 * * * /bin/bash /root/pg_backup_encrypt.sh' >> "$CR"
crontab "$CR"
rm -f "$CR"
crontab -l | grep -v '^#' | grep -v '^$'

echo ''
echo '=== 평문이 밖으로 나갈 일이 없는지 ==='
echo "평문 폴더: /root/backups (서버 안에만 둔다)"
echo "반출 폴더: /root/backups/enc (잠긴 것만)"
