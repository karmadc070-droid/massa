#!/bin/sh
# 백업을 암호화해서 밖으로 보내려면 무엇이 깔려 있는지 먼저 본다.
echo '=== 도구 ==='
for c in openssl age rclone aws gpg curl tar gzip; do
  printf '%-8s %s\n' "$c" "$(command -v $c 2>/dev/null || echo '없음')"
done
echo ''
echo '=== 백업 폴더 ==='
ls -1 /root/backups/*.sql.gz 2>/dev/null | wc -l | sed 's/^/sql.gz 개수: /'
du -sh /root/backups 2>/dev/null
ls -lt /root/backups/massa-db_*.sql.gz 2>/dev/null | head -3
echo ''
echo '=== massa 덤프에 개인정보가 있는지 (값은 보지 않고 칸 이름만) ==='
LATEST=$(ls -1t /root/backups/massa-db_*.sql.gz 2>/dev/null | head -1)
if [ -n "$LATEST" ]; then
  echo "대상: $LATEST"
  zcat "$LATEST" | grep -m1 -o 'COPY public.profiles ([^)]*)' || echo '  profiles COPY 못 찾음'
  zcat "$LATEST" | grep -m1 -o 'COPY public.provider_kyc ([^)]*)' || echo '  provider_kyc COPY 못 찾음'
fi
echo ''
echo '=== 디스크 여유 ==='
df -h / | tail -1
