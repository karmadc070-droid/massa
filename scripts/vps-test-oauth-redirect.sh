#!/bin/sh
# 소셜 로그인이 새 주소로 돌아올 수 있는지, 공급자 콘솔을 건드려야 하는지 확인한다.
#
# 구조를 먼저 짚는다.
#   앱(app.massaviet.com) → GoTrue authorize → 구글/카카오/애플
#   → **GoTrue 콜백**(api.moahagwon.com/auth/v1/callback) → GoTrue → redirect_to(앱)
#
# 공급자 콘솔에 등록하는 것은 가운데의 **GoTrue 콜백 주소**다. 앱 주소가 아니다.
# 그래서 앱 도메인이 바뀌어도 콘솔은 그대로여야 정상이다. 정말 그런지 본다.

echo '=== 1. GoTrue 콜백 주소 (공급자 콘솔에 등록돼 있어야 하는 값) ==='
grep -E '^API_EXTERNAL_URL=' /root/massa/.env | cut -d= -f2- | sed 's|$|/auth/v1/callback|' | sed 's/^/  /'

echo ''
echo '=== 2. 새 주소로 authorize 를 걸면 어디로 보내는가 ==='
for p in google kakao apple; do
  echo "  --- $p ---"
  LOC=$(curl -s -o /dev/null -D - \
    "https://api.moahagwon.com/auth/v1/authorize?provider=$p&redirect_to=https%3A%2F%2Fapp.massaviet.com%2F" \
    | grep -i '^location:' | head -1 | cut -c11-)
  # 공급자 호스트와 redirect_uri 만 보여 준다. 클라이언트 ID 는 찍지 않는다.
  echo "$LOC" | sed -E 's|\?.*||'            | sed 's/^/    보내는 곳: /'
  echo "$LOC" | grep -oE 'redirect_uri=[^&]*' | sed 's/^/    /' | head -1
  echo "$LOC" | grep -qi 'error' && echo '    ★ 오류 응답' || true
done

echo ''
echo '=== 3. 허용목록에 없는 주소를 넣으면 막히는가 (대조군) ==='
LOC=$(curl -s -o /dev/null -D - \
  "https://api.moahagwon.com/auth/v1/authorize?provider=google&redirect_to=https%3A%2F%2Fevil.example.com%2F" \
  | grep -i '^location:' | head -1 | cut -c11-)
echo "$LOC" | sed -E 's|\?.*||' | sed 's/^/  보내는 곳: /'
echo "$LOC" | grep -oE 'redirect_uri=[^&]*' | sed 's/^/  /' | head -1
