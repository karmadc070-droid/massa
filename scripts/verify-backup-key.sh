#!/bin/bash
# 사장님 PC 에 있는 개인키로 서버가 잠근 백업이 정말 열리는지 확인한다.
# 이게 통과해야 백업이 백업이다. 안 열리면 아무도 못 여는 파일 더미일 뿐이다.
#
# Git bash 로 실행한다 (윈도 경로를 gpg 가 못 읽어서 POSIX 경로를 쓴다).
set -e
D=/c/Users/user/massa-backup-key
export GNUPGHOME="$D/gnupg-test"

rm -rf "$GNUPGHOME"
mkdir -p "$GNUPGHOME"
chmod 700 "$GNUPGHOME" 2>/dev/null || true
cd "$D"

echo '=== 1. 열쇠 가져오기 ==='
gpg --batch --yes --import massa-backup-pub.asc 2>&1 | tail -2
gpg --batch --yes --import massa-backup-private.asc 2>&1 | tail -2

echo ''
echo '=== 2. 개인키가 들어왔는가 ==='
if gpg --list-secret-keys massa-backup >/dev/null 2>&1; then
  echo '  통과 — 개인키 있음'
  gpg --with-colons --fingerprint massa-backup | awk -F: '/^fpr:/{print "  지문: " $10; exit}'
else
  echo '  ★ 실패 — 개인키가 없다'; exit 1
fi

echo ''
echo '=== 3. ★ 서버가 잠근 백업을 여기서 열어 본다 ==='
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
    --decrypt --output restore-test.sql.gz restore-test.gpg 2>/dev/null
echo "  푼 크기: $(stat -c %s restore-test.sql.gz) bytes"

echo ''
echo '=== 4. ★ 서버 원본과 같은 파일인가 (sha256) ==='
GOT=$(sha256sum restore-test.sql.gz | cut -d' ' -f1)
echo "  여기: $GOT"
echo "  서버: $EXPECT_SHA"
if [ "$GOT" = "$EXPECT_SHA" ]; then echo '  통과 — 같다'; else echo '  ★ 실패 — 다르다'; exit 1; fi

echo ''
echo '=== 5. ★ 진짜 복구 가능한 덤프인가 ==='
if zcat restore-test.sql.gz | head -40 | grep -q 'PostgreSQL database dump'; then
  echo "  통과 — pg_dump 파일 · 표 $(zcat restore-test.sql.gz | grep -c '^COPY public\.')개"
else
  echo '  ★ 실패 — 덤프 형식이 아니다'; exit 1
fi

echo ''
echo '=== 뒷정리 (시험용 키링과 푼 파일은 지운다) ==='
rm -f restore-test.sql.gz
rm -rf "$GNUPGHOME"
echo '완료 — 개인키 원본(massa-backup-private.asc)은 그대로 둔다'
