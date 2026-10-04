#!/bin/sh
# 앞 스크립트가 evil 주소를 '허용' 으로 찍었다. 분기 실수인지 진짜 구멍인지 Location 을 그대로 본다.
# 차단이라면 GoTrue 는 SITE_URL(app.massaviet.com)로 돌려보낸다 — 그건 정상이다.
# 진짜 구멍이라면 Location 에 evil.example.com 이 그대로 들어 있다.
for U in \
  'https://admin.massaviet.com/reset.html' \
  'https://evil.example.com/x' ; do
  L=$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 20 \
      "https://api.moahagwon.com/auth/v1/verify?token=dummy&type=recovery&redirect_to=$U")
  echo "요청: $U"
  echo "  Location: $L"
  if printf '%s' "$L" | grep -q 'evil\.example\.com'; then
    echo '  >>> 열린 리다이렉트다. 막아야 한다.'
  else
    echo '  >>> evil 주소로는 안 보낸다 (차단됨)'
  fi
  echo ''
done
