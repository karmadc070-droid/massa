#!/bin/sh
# 개인키를 반출용 파일로 뽑는다. 내용은 화면에 찍지 않는다.
# 사장님 PC 로 옮긴 뒤 vps-backup-key-wipe.sh 로 서버에서 지운다.
set -e
GNUPGHOME=/root/.gnupg-massa
export GNUPGHOME

OUT=/root/massa-backup-private.asc
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
    --armor --export-secret-keys massa-backup > "$OUT"
chmod 600 "$OUT"

# 값이 아니라 크기와 형식만 확인한다
echo "파일: $OUT"
echo "크기: $(stat -c %s "$OUT") bytes"
head -1 "$OUT"
tail -1 "$OUT"
echo "줄 수: $(wc -l < "$OUT")"
