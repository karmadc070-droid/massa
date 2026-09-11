#!/bin/bash
# 진짜 재난 상황을 흉내낸다: 서버가 없다고 치고 R2 에 있는 파일만으로 복구되는가.
#   R2 에서 내려받기 → 사장님 PC 개인키로 풀기 → 정상 덤프인지 확인
# 이게 통과해야 "백업이 있다"고 말할 수 있다.
set -e
D=/c/Users/user/massa-backup-key
export GNUPGHOME="$D/gnupg-restore"
cd "$D"

echo '=== 1. 열쇠 준비 ==='
rm -rf "$GNUPGHOME"; mkdir -p "$GNUPGHOME"; chmod 700 "$GNUPGHOME" 2>/dev/null || true
gpg --batch --yes --import massa-backup-pub.asc 2>&1 | tail -1
gpg --batch --yes --import massa-backup-private.asc 2>&1 | tail -1

echo ''
echo "=== 2. R2 에서 내려받기: $R2_NAME ==="
ls -la "$R2_NAME"

echo ''
echo '=== 3. 개인키로 풀기 ==='
rm -f restore-out.sql.gz
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
    --decrypt --output restore-out.sql.gz "$R2_NAME" 2>/dev/null
echo "  푼 크기: $(stat -c %s restore-out.sql.gz) bytes"

echo ''
echo '=== 4. 서버 원본과 같은가 ==='
GOT=$(sha256sum restore-out.sql.gz | cut -d' ' -f1)
echo "  복구본: $GOT"
echo "  서버  : $EXPECT_SHA"
[ "$GOT" = "$EXPECT_SHA" ] && echo '  통과' || { echo '  ★ 실패'; exit 1; }

echo ''
echo '=== 5. 실제로 복구에 쓸 수 있는 덤프인가 ==='
if zcat restore-out.sql.gz | head -40 | grep -q 'PostgreSQL database dump'; then
  echo "  통과 — 표 $(zcat restore-out.sql.gz | grep -c '^COPY public\.')개"
  echo '  들어 있는 주요 표:'
  zcat restore-out.sql.gz | grep -o '^COPY public\.[a-z_]*' | sed 's/COPY public\./    /' | head -8
else
  echo '  ★ 실패'; exit 1
fi

echo ''
echo '=== 뒷정리 ==='
rm -f restore-out.sql.gz "$R2_NAME"
rm -rf "$GNUPGHOME"
echo '완료 (개인키 원본은 그대로 둔다)'
