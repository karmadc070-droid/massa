#!/bin/sh
# GoTrue 에 구글·카카오·애플 로그인 설정을 넣는다.
# 키는 /root/massa/.env 에 사장님이 직접 넣는다. 값이 비어 있으면 해당 provider 는 꺼진 채로 남는다.
# 앱은 /auth/v1/settings 를 읽어 켜진 것만 버튼을 보여주므로, 키가 없어도 안전하다.
set -e

COMPOSE=/root/massa/docker-compose.yml
ENVF=/root/massa/.env

cp "$COMPOSE" "$COMPOSE.bak.$(date +%s)"
cp "$ENVF" "$ENVF.bak.$(date +%s)"

# ── docker-compose 에 provider 매핑 추가 ──────────────────────────
# 이미 넣었으면 건너뛴다
if grep -q "GOTRUE_EXTERNAL_KAKAO_ENABLED" "$COMPOSE"; then
  echo "compose 에 이미 등록돼 있음"
else
  python3 - <<'PY'
import re
p = "/root/massa/docker-compose.yml"
s = open(p, encoding="utf-8").read()

anchor = "      GOTRUE_EXTERNAL_PHONE_ENABLED:"
block = """      GOTRUE_EXTERNAL_GOOGLE_ENABLED: ${GOOGLE_ENABLED:-false}
      GOTRUE_EXTERNAL_GOOGLE_CLIENT_ID: ${GOOGLE_CLIENT_ID:-}
      GOTRUE_EXTERNAL_GOOGLE_SECRET: ${GOOGLE_SECRET:-}
      GOTRUE_EXTERNAL_GOOGLE_REDIRECT_URI: ${API_EXTERNAL_URL}/auth/v1/callback
      GOTRUE_EXTERNAL_KAKAO_ENABLED: ${KAKAO_ENABLED:-false}
      GOTRUE_EXTERNAL_KAKAO_CLIENT_ID: ${KAKAO_CLIENT_ID:-}
      GOTRUE_EXTERNAL_KAKAO_SECRET: ${KAKAO_SECRET:-}
      GOTRUE_EXTERNAL_KAKAO_REDIRECT_URI: ${API_EXTERNAL_URL}/auth/v1/callback
      GOTRUE_EXTERNAL_APPLE_ENABLED: ${APPLE_ENABLED:-false}
      GOTRUE_EXTERNAL_APPLE_CLIENT_ID: ${APPLE_CLIENT_ID:-}
      GOTRUE_EXTERNAL_APPLE_SECRET: ${APPLE_SECRET:-}
      GOTRUE_EXTERNAL_APPLE_REDIRECT_URI: ${API_EXTERNAL_URL}/auth/v1/callback
"""
idx = s.index(anchor)
s = s[:idx] + block + s[idx:]
open(p, "w", encoding="utf-8").write(s)
print("compose 에 provider 12줄 추가")
PY
fi

# ── .env 에 빈 자리 만들기 ──────────────────────────────────────
add_env() {
  grep -q "^$1=" "$ENVF" || echo "$1=$2" >> "$ENVF"
}
add_env GOOGLE_ENABLED false
add_env GOOGLE_CLIENT_ID ""
add_env GOOGLE_SECRET ""
add_env KAKAO_ENABLED false
add_env KAKAO_CLIENT_ID ""
add_env KAKAO_SECRET ""
add_env APPLE_ENABLED false
add_env APPLE_CLIENT_ID ""
add_env APPLE_SECRET ""

echo
echo "=== .env 소셜 설정 (값은 가림) ==="
grep -E "^(GOOGLE|KAKAO|APPLE)_" "$ENVF" | sed 's/\(SECRET\|CLIENT_ID\)=.*/\1=***/'

echo
echo "=== auth 컨테이너 재생성 ==="
cd /root/massa
docker compose up -d auth
sleep 8

echo
echo "=== 적용 확인 ==="
docker exec massa-auth env | grep -E "GOTRUE_EXTERNAL_(GOOGLE|KAKAO|APPLE)_ENABLED" || echo "(설정 없음)"

echo
echo "=== settings 응답 ==="
curl -s https://api.moahagwon.com/auth/v1/settings | head -c 400
echo
echo "=== SOCIAL SETUP DONE ==="
