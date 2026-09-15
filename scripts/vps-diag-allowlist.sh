#!/bin/sh
# SITE_URL 을 바꾼 뒤 옛 주소가 튕기기 시작했다. 허용목록이 살아 있는지 본다.
echo '=== .env 의 값 ==='
grep -E '^(SITE_URL|ADDITIONAL_REDIRECT_URLS)=' /root/massa/.env | sed 's/^/  /'

echo ''
echo '=== 컨테이너 안의 값 ==='
docker exec massa-auth sh -c 'echo "  SITE_URL      = $GOTRUE_SITE_URL"; echo "  URI_ALLOW_LIST= $GOTRUE_URI_ALLOW_LIST"'

echo ''
echo '=== 각 주소를 하나씩 확인 ==='
KEY=$(grep -E '^ANON_KEY=' /root/massa/.env | cut -d= -f2-)
chk() {
  printf '  %-46s ' "$1"
  curl -s -o /dev/null -D - \
    "https://api.moahagwon.com/auth/v1/verify?token=bogus&type=recovery&redirect_to=$2" \
    -H "apikey: $KEY" | grep -i '^location:' | head -1 | cut -c11- | sed 's/#.*//' | tr -d '\r'
  echo ''
}
chk 'app.massaviet.com/reset.html'      'https%3A%2F%2Fapp.massaviet.com%2Freset.html'
chk 'massa.moahagwon.com/reset.html'    'https%3A%2F%2Fmassa.moahagwon.com%2Freset.html'
chk 'massa.moahagwon.com (경로 없음)'    'https%3A%2F%2Fmassa.moahagwon.com'
chk 'massaviet.com/'                    'https%3A%2F%2Fmassaviet.com%2F'
chk 'evil.example.com (대조군)'          'https%3A%2F%2Fevil.example.com%2F'
