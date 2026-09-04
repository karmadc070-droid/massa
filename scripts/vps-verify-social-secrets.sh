#!/bin/sh
# 소셜 로그인 시크릿이 진짜 맞는지 실계정 없이 확인한다.
#
# 원리: 각 provider 의 토큰 엔드포인트에 "일부러 틀린 code" 로 요청한다.
#   - 시크릿이 틀리면  → invalid_client (클라이언트 인증 자체가 실패)
#   - 시크릿이 맞으면  → invalid_grant  (클라이언트는 통과, code 만 틀림)
# 즉 invalid_grant 가 나와야 정상이다. 값은 출력하지 않는다.
set -e

ENVF=/root/massa/.env
CB=https://api.moahagwon.com/auth/v1/callback
get() { grep "^$1=" "$ENVF" | head -1 | cut -d= -f2-; }

echo "=== 구글 ==="
curl -s -X POST https://oauth2.googleapis.com/token \
  -d "client_id=$(get GOOGLE_CLIENT_ID)" \
  -d "client_secret=$(get GOOGLE_SECRET)" \
  -d "code=intentionally-invalid" \
  -d "grant_type=authorization_code" \
  -d "redirect_uri=$CB" | head -c 200
echo

echo "=== 카카오 ==="
curl -s -X POST https://kauth.kakao.com/oauth/token \
  -d "client_id=$(get KAKAO_CLIENT_ID)" \
  -d "client_secret=$(get KAKAO_SECRET)" \
  -d "code=intentionally-invalid" \
  -d "grant_type=authorization_code" \
  -d "redirect_uri=$CB" | head -c 200
echo

echo "=== 애플 ==="
curl -s -X POST https://appleid.apple.com/auth/token \
  -d "client_id=$(get APPLE_CLIENT_ID)" \
  -d "client_secret=$(get APPLE_SECRET)" \
  -d "code=intentionally-invalid" \
  -d "grant_type=authorization_code" \
  -d "redirect_uri=$CB" | head -c 200
echo
echo "=== VERIFY DONE ==="
