#!/bin/sh
# 구글은 브라우저로 끝까지 돌려봤다. 카카오·애플은 실제 계정이 없어 왕복을 못 한다.
# 대신 '우리 쪽에서 내보내는 것' 까지는 전부 맞는지 본다 — 공급자 켜짐, 302 목적지, 돌아올 주소.
KEY=$(grep -E '^ANON_KEY=' /root/massa/.env | cut -d= -f2-)

echo '=== 공급자가 서버에 켜져 있나 ==='
curl -s --max-time 20 -H "apikey: $KEY" https://api.moahagwon.com/auth/v1/settings \
  | tr ',{}' '\n' | grep -E '"(google|kakao|apple|email)"' | sed 's/^/  /'

echo ''
echo '=== 앱(app.massaviet.com)에서 세 공급자 ==='
for P in google kakao apple; do
  L=$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 20 -H "apikey: $KEY" \
      "https://api.moahagwon.com/auth/v1/authorize?provider=$P&redirect_to=https%3A%2F%2Fapp.massaviet.com%2F")
  HOST=$(printf '%s' "$L" | awk -F/ '{print $3}')
  OK=$(printf '%s' "$L" | grep -c 'redirect_uri=https%3A%2F%2Fapi.moahagwon.com%2Fauth%2Fv1%2Fcallback')
  printf '  %-7s -> %-28s 콜백주소맞음:%s\n' "$P" "${HOST:-없음}" "$OK"
done

echo ''
echo '=== 콘솔(admin.massaviet.com)에서 ==='
for P in google kakao apple; do
  L=$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 20 -H "apikey: $KEY" \
      "https://api.moahagwon.com/auth/v1/authorize?provider=$P&redirect_to=https%3A%2F%2Fadmin.massaviet.com%2F")
  printf '  %-7s -> %s\n' "$P" "$(printf '%s' "$L" | awk -F/ '{print $3}')"
done

echo ''
echo '=== 이메일 가입이 켜져 있나 (소셜이 막혀도 들어올 길) ==='
curl -s --max-time 20 -H "apikey: $KEY" https://api.moahagwon.com/auth/v1/settings \
  | tr ',{}' '\n' | grep -E 'disable_signup|mailer_autoconfirm' | sed 's/^/  /'
