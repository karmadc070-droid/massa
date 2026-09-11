#!/bin/sh
# R2 토큰을 rclone 설정에 넣고, 잠긴 백업을 올린 뒤 왕복까지 확인한다.
#
# 사장님이 /root/r2.key 에 두 줄만 넣어 두면 된다.
#   첫 줄: Access Key ID
#   둘째 줄: Secret Access Key
# 값은 화면에 찍지 않는다. 길이만 보여 준다. 다 쓰면 shred 로 지운다.
set -e

SRC=/root/r2.key
ACCOUNT=858e5877f6c56870cf30d4b1ba41d47a
BUCKET=massa-db-backup
ENC=/root/backups/enc

[ -f "$SRC" ] || { echo "★ $SRC 가 없습니다. Access Key ID 와 Secret 을 두 줄로 저장한 뒤 다시 실행하세요."; exit 1; }

AKID=$(sed -n '1p' "$SRC" | tr -d ' \t\r\n')
SECRET=$(sed -n '2p' "$SRC" | tr -d ' \t\r\n')
[ -n "$AKID" ] && [ -n "$SECRET" ] || { echo '★ 두 줄이 모두 채워져 있어야 합니다.'; exit 1; }
echo "Access Key ID 길이: ${#AKID} · Secret 길이: ${#SECRET}"

# ── rclone 설정 ──────────────────────────────────────────────
mkdir -p /root/.config/rclone
cat > /root/.config/rclone/rclone.conf <<EOF
[r2]
type = s3
provider = Cloudflare
access_key_id = $AKID
secret_access_key = $SECRET
endpoint = https://$ACCOUNT.r2.cloudflarestorage.com
acl = private
no_check_bucket = true
EOF
chmod 600 /root/.config/rclone/rclone.conf
echo '설정 파일 작성됨 (권한 600, 값은 출력하지 않음)'

shred -u "$SRC" 2>/dev/null || rm -f "$SRC"
echo '토큰 파일 삭제됨'

# ── 연결 확인 ────────────────────────────────────────────────
echo ''
echo '=== 1. 버킷이 보이는가 ==='
rclone lsd r2: 2>&1 | head -5

echo ''
echo '=== 2. 잠긴 백업 올리기 ==='
rclone copy "$ENC" "r2:$BUCKET/enc" --transfers 4 --stats-one-line 2>&1 | tail -3
echo "올라간 파일: $(rclone ls "r2:$BUCKET/enc" 2>/dev/null | wc -l)개"

echo ''
echo '=== 3. ★ 올린 파일이 서버 것과 같은가 (내려받아 대조) ==='
LATEST=$(ls -1t "$ENC"/massa-db_*.gpg | head -1)
NAME=$(basename "$LATEST")
TMP=$(mktemp -d)
rclone copyto "r2:$BUCKET/enc/$NAME" "$TMP/$NAME" 2>&1 | tail -1
A=$(sha256sum "$LATEST" | cut -d' ' -f1)
B=$(sha256sum "$TMP/$NAME" | cut -d' ' -f1)
echo "  서버: $A"
echo "  R2  : $B"
[ "$A" = "$B" ] && echo '  통과 — 같다' || { echo '  ★ 실패 — 다르다'; rm -rf "$TMP"; exit 1; }
rm -rf "$TMP"

echo ''
echo '=== 4. 평문이 올라가지 않았는가 (0 이어야 한다) ==='
rclone ls "r2:$BUCKET" 2>/dev/null | grep -vc '\.gpg$' || echo 0

echo ''
echo '=== 완료 ==='
rclone size "r2:$BUCKET" 2>&1 | tail -2
