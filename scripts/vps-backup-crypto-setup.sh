#!/bin/sh
# 백업을 서버 밖으로 보내기 위한 암호화 준비.
#
# 왜 비대칭인가:
#   덤프에는 profiles.phone, provider_kyc.bank_account, id_front_url 같은 개인정보가 들어 있다.
#   암호만 쓰는 방식(대칭)은 그 암호가 서버에 있어야 해서, 서버가 털리면 백업도 같이 털린다.
#   공개키로 잠그면 서버에는 '잠그는 열쇠'만 남는다. 푸는 열쇠는 사장님 PC 에만 둔다.
#
# 이 스크립트는 열쇠를 만들고 **왕복 시험까지 한 뒤** 결과를 알려 준다.
# 개인키 반출과 삭제는 다음 단계(vps-backup-key-export.sh)에서 한다.
set -e

GNUPGHOME=/root/.gnupg-massa
export GNUPGHOME
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME"

KEYID="massa-backup"

if gpg --list-keys "$KEYID" >/dev/null 2>&1; then
  echo "열쇠가 이미 있다. 새로 만들지 않는다."
else
  echo '=== 열쇠 생성 (RSA 4096) ==='
  # 암호 없는 개인키다. 파일 자체가 비밀이므로 사장님 PC 에 옮긴 뒤 서버에서 지운다.
  # 암호를 걸면 자동 복구 때 사람이 매번 쳐야 하고, 잊으면 백업 전체를 못 연다.
  gpg --batch --pinentry-mode loopback --passphrase '' --quick-generate-key \
      "$KEYID (massa DB backup) <backup@massaviet.com>" rsa4096 encr never
fi

echo ''
echo '=== 열쇠 지문 (이 값은 비밀이 아니다) ==='
gpg --fingerprint "$KEYID" | sed -n '2p'

echo ''
echo '=== 공개키를 따로 뽑아 둔다 (앞으로 잠글 때 이것만 쓴다) ==='
gpg --armor --export "$KEYID" > /root/backups/massa-backup-pub.asc
ls -la /root/backups/massa-backup-pub.asc

echo ''
echo '=== ★ 왕복 시험 — 진짜 덤프를 잠갔다가 다시 열어 본다 ==='
LATEST=$(ls -1t /root/backups/massa-db_*.sql.gz | head -1)
echo "대상: $LATEST ($(stat -c %s "$LATEST") bytes)"

TMP=$(mktemp -d)
gpg --batch --yes --trust-model always --encrypt --recipient "$KEYID" \
    --output "$TMP/t.gpg" "$LATEST"
echo "잠근 뒤: $(stat -c %s "$TMP/t.gpg") bytes"

gpg --batch --yes --pinentry-mode loopback --passphrase '' \
    --decrypt --output "$TMP/t.gz" "$TMP/t.gpg" 2>/dev/null
echo "푼 뒤:   $(stat -c %s "$TMP/t.gz") bytes"

A=$(sha256sum "$LATEST" | cut -d' ' -f1)
B=$(sha256sum "$TMP/t.gz" | cut -d' ' -f1)
if [ "$A" = "$B" ]; then echo '  통과 — 원본과 한 바이트도 다르지 않다'; else echo '  ★ 실패 — 내용이 달라졌다'; rm -rf "$TMP"; exit 1; fi

echo ''
echo '=== ★ 푼 파일이 진짜 복구 가능한 덤프인지 ==='
if zcat "$TMP/t.gz" | head -40 | grep -q 'PostgreSQL database dump'; then
  echo '  통과 — 정상적인 pg_dump 파일이다'
  zcat "$TMP/t.gz" | grep -c '^COPY public\.' | sed 's/^/  표 개수: /'
else
  echo '  ★ 실패 — 덤프 형식이 아니다'; rm -rf "$TMP"; exit 1
fi

rm -rf "$TMP"
echo ''
echo '=== 준비 끝 ==='
echo '다음: 개인키를 사장님 PC 로 옮기고 서버에서 지운다 (vps-backup-key-export.sh)'
