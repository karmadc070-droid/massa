#!/bin/sh
# SITE_URL 을 옮겼더니 massa.moahagwon.com/reset.html 이 튕기기 시작했다.
#
# 원인: 그 호스트는 허용목록에 `/*` 만 있었다. 전에 통과한 건 허용목록 덕이 아니라
# **SITE_URL 이 그 주소였기 때문**이다 (GoTrue 는 SITE_URL 을 항상 허용한다).
# SITE_URL 을 옮기는 순간 그 우산이 사라졌다.
#
# 잘 되는 항목(massaviet.com·app.massaviet.com)은 `/*` 와 `/**` 를 **둘 다** 갖고 있었다.
# 같은 모양으로 맞춘다.
#
# 왜 중요한가: 이미 나간 비밀번호 재설정 메일의 링크가 옛 주소를 담고 있다.
# 그게 튕기면 손님이 토큰을 들고 엉뚱한 화면에 떨어진다.
set -e
ENVF=/root/massa/.env

echo '=== 이전 ==='
grep -E '^ADDITIONAL_REDIRECT_URLS=' "$ENVF" | cut -d= -f2- | tr ',' '\n' | sed 's/^/  /'

CUR=$(grep -E '^ADDITIONAL_REDIRECT_URLS=' "$ENVF" | cut -d= -f2-)
ADD=''
for H in https://massa.moahagwon.com https://admin.moahagwon.com; do
  case "$CUR" in
    *"$H/**"*) ;;
    *) ADD="$ADD,$H/**" ;;
  esac
done
[ -n "$ADD" ] || { echo '이미 다 있음 — 건너뜀'; exit 0; }

cp "$ENVF" "$ENVF.bak.$(date +%s)"
sed -i "s|^ADDITIONAL_REDIRECT_URLS=.*|ADDITIONAL_REDIRECT_URLS=$CUR$ADD|" "$ENVF"

echo ''
echo '=== 이후 ==='
grep -E '^ADDITIONAL_REDIRECT_URLS=' "$ENVF" | cut -d= -f2- | tr ',' '\n' | sed 's/^/  /'

cd /root/massa
docker compose up -d auth >/dev/null 2>&1
sleep 8
docker ps --filter name=massa-auth --format '  {{.Names}} {{.Status}}'

echo ''
echo '=== 다시 판정 ==='
KEY=$(grep -E '^ANON_KEY=' "$ENVF" | cut -d= -f2-)
chk() {
  printf '  %-40s ' "$1"
  curl -s -o /dev/null -D - \
    "https://api.moahagwon.com/auth/v1/verify?token=bogus&type=recovery&redirect_to=$2" \
    -H "apikey: $KEY" | grep -i '^location:' | head -1 | cut -c11- | sed 's/#.*//' | tr -d '\r'
  echo ''
}
chk 'app.massaviet.com/reset.html'   'https%3A%2F%2Fapp.massaviet.com%2Freset.html'
chk 'massa.moahagwon.com/reset.html' 'https%3A%2F%2Fmassa.moahagwon.com%2Freset.html'
chk 'admin.moahagwon.com/index.html' 'https%3A%2F%2Fadmin.moahagwon.com%2Findex.html'
chk 'evil.example.com (튕겨야 함)'    'https%3A%2F%2Fevil.example.com%2F'
