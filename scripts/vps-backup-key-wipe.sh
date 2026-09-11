#!/bin/sh
# 서버에서 개인키를 지운다. 이 뒤로 서버는 '잠글' 수만 있고 '열' 수는 없다.
# 서버가 털려도 백업 내용은 안전하다. 여는 열쇠는 사장님 PC 에만 있다.
set -e
GNUPGHOME=/root/.gnupg-massa
export GNUPGHOME

FPR=$(gpg --with-colons --fingerprint massa-backup | awk -F: '/^fpr:/{print $10; exit}')
echo "지문: $FPR"

gpg --batch --yes --delete-secret-keys "$FPR"
shred -u /root/massa-backup-private.asc 2>/dev/null || rm -f /root/massa-backup-private.asc

echo ''
echo '=== 확인 1. 반출 파일이 사라졌는가 ==='
[ -f /root/massa-backup-private.asc ] && echo '  ★ 아직 있다' || echo '  통과 — 없다'

echo '=== 확인 2. 개인키가 키링에서 사라졌는가 ==='
if gpg --list-secret-keys massa-backup >/dev/null 2>&1; then echo '  ★ 아직 있다'; else echo '  통과 — 없다'; fi

echo '=== 확인 3. 그래도 잠그는 것은 되는가 ==='
TMP=$(mktemp -d)
echo 'massa backup crypto check' > "$TMP/a.txt"
gpg --batch --yes --trust-model always --encrypt --recipient massa-backup --output "$TMP/a.gpg" "$TMP/a.txt"
[ -s "$TMP/a.gpg" ] && echo '  통과 — 잠글 수 있다' || echo '  ★ 실패'

echo '=== 확인 4. ★ 서버에서는 못 여는가 (여기서 열리면 안 된다) ==='
if gpg --batch --yes --pinentry-mode loopback --passphrase '' --decrypt --output "$TMP/a2.txt" "$TMP/a.gpg" 2>/dev/null; then
  echo '  ★ 실패 — 서버에서 열렸다. 개인키가 남아 있다'
else
  echo '  통과 — 서버에서는 열 수 없다'
fi
rm -rf "$TMP"
