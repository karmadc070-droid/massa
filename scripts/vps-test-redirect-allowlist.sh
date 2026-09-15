#!/bin/sh
# 허용목록이 실제로 동작하는지 비밀번호 없이 증명한다.
#
# 첫 시도(recover 엔드포인트)는 실패했다. 셋 다 200 이 나왔다.
# GoTrue 는 요청을 받을 때가 아니라 **돌려보낼 때** redirect_to 를 판정하기 때문이다.
# 그래서 판정이 실제로 일어나는 verify 단계에 건다. 토큰은 엉터리여도 된다 —
# 우리가 보는 것은 "어디로 돌려보내는가"(Location 헤더)지 인증 성공 여부가 아니다.
set -e
API=https://api.moahagwon.com
KEY=$(grep -E '^ANON_KEY=' /root/massa/.env | cut -d= -f2-)

look() {
  printf '  %-40s\n' "$2"
  LOC=$(curl -s -o /dev/null -D - \
    "$API/auth/v1/verify?token=bogus-token-for-allowlist-test&type=recovery&redirect_to=$1" \
    -H "apikey: $KEY" | grep -i '^location:' | head -1 | cut -c11- | tr -d '\r')
  # 조각(#) 앞부분만 본다. 뒤는 오류 메시지라 볼 필요 없다.
  echo "    돌려보낸 곳: $(echo "$LOC" | sed 's/#.*//')"
}

echo '=== 허용목록에 있는 주소 — 그 주소로 돌아가야 한다 ==='
look 'https%3A%2F%2Fapp.massaviet.com%2Freset.html' 'app.massaviet.com (새 주소)'
look 'https%3A%2F%2Fmassa.moahagwon.com%2Freset.html' 'massa.moahagwon.com (기존)'

echo ''
echo '=== 허용목록 밖 — SITE_URL 로 튕겨야 한다 ==='
look 'https%3A%2F%2Fevil.example.com%2Fsteal' 'evil.example.com'

echo ''
echo '=== 참고: SITE_URL ==='
docker exec massa-auth sh -c 'echo "    $GOTRUE_SITE_URL"'
