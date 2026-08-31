#!/bin/sh
# 애플 .p8 개인키로 Sign in with Apple 클라이언트 시크릿(JWT)을 VPS 안에서 직접 만든다.
#
# 사전 준비 — VPS 에 아래 두 가지를 올려둘 것.
#   1) /root/apple.p8        : 애플에서 받은 키 파일 원본 그대로
#   2) /root/apple.conf      : 아래 3줄
#        APPLE_KEY_ID=XXXXXXXXXX
#        APPLE_TEAM_ID=GRF3HK77HU
#        APPLE_CLIENT_ID=app.massa.hanoi.web
#
# 만든 JWT 는 /root/social.keys 에 APPLE_* 로 append 되고,
# 이어서 vps-apply-social-keys.sh 를 돌리면 .env 에 반영된다.
# .p8 원본은 이 스크립트가 끝나면서 지운다.
set -e

P8=/root/apple.p8
CONF=/root/apple.conf
OUT=/root/social.keys

[ -f "$P8" ]   || { echo "$P8 없음"; exit 1; }
[ -f "$CONF" ] || { echo "$CONF 없음"; exit 1; }

. "$CONF"
[ -n "$APPLE_KEY_ID" ]    || { echo "APPLE_KEY_ID 없음"; exit 1; }
[ -n "$APPLE_TEAM_ID" ]   || { echo "APPLE_TEAM_ID 없음"; exit 1; }
[ -n "$APPLE_CLIENT_ID" ] || { echo "APPLE_CLIENT_ID 없음"; exit 1; }

python3 -c "import cryptography" 2>/dev/null || pip3 install --break-system-packages cryptography

JWT=$(python3 - "$P8" "$APPLE_KEY_ID" "$APPLE_TEAM_ID" "$APPLE_CLIENT_ID" <<'PY'
import sys, json, time, base64
from cryptography.hazmat.primitives.serialization import load_pem_private_key
from cryptography.hazmat.primitives.asymmetric import ec, utils
from cryptography.hazmat.primitives import hashes

p8, kid, team, client = sys.argv[1:5]
key = load_pem_private_key(open(p8, 'rb').read(), password=None)

def b64(b):
    return base64.urlsafe_b64encode(b).rstrip(b'=').decode()

now = int(time.time())
# 애플이 허용하는 최대 수명은 6개월(15777000초)
exp = now + 15777000
header = {"alg": "ES256", "kid": kid}
payload = {"iss": team, "iat": now, "exp": exp,
           "aud": "https://appleid.apple.com", "sub": client}

signing_input = (b64(json.dumps(header, separators=(',', ':')).encode()) + '.' +
                 b64(json.dumps(payload, separators=(',', ':')).encode()))

der = key.sign(signing_input.encode(), ec.ECDSA(hashes.SHA256()))
r, s = utils.decode_dss_signature(der)
raw = r.to_bytes(32, 'big') + s.to_bytes(32, 'big')

print(signing_input + '.' + b64(raw))
import datetime
print('EXPIRES=' + datetime.datetime.utcfromtimestamp(exp).strftime('%Y-%m-%d'), file=sys.stderr)
PY
)

EXPIRES=$(python3 -c "import time,datetime;print(datetime.datetime.utcfromtimestamp(time.time()+15777000).strftime('%Y-%m-%d'))")

touch "$OUT"
grep -v '^APPLE_' "$OUT" > "$OUT.tmp" 2>/dev/null || true
mv "$OUT.tmp" "$OUT"
{
  echo "APPLE_CLIENT_ID=$APPLE_CLIENT_ID"
  echo "APPLE_SECRET=$JWT"
} >> "$OUT"
chmod 600 "$OUT"

echo "JWT 생성 완료 (길이 ${#JWT})"
echo "만료일: $EXPIRES  ← 달력에 적어둘 것. 지나면 애플 로그인이 끊긴다."
echo "$OUT 에 APPLE_CLIENT_ID / APPLE_SECRET 기록함"

shred -u "$P8" "$CONF" 2>/dev/null || rm -f "$P8" "$CONF"
echo ".p8 원본과 conf 는 삭제함"
echo "=== APPLE SECRET DONE ==="
