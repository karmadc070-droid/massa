#!/bin/sh
# 고객이 실제로 받아서 쓸 수 있는지 확인한다. 네 군데가 전부 살아 있어야 한다.
#   1) 스토어 페이지가 공개돼 있나 (받을 수 있나)
#   2) 받은 뒤 앱이 불러오는 화면이 살아 있나  <- 여기가 죽으면 받아도 흰 화면이다
#   3) 안드로이드 TWA 가 보는 Vercel 프록시가 VPS 최신을 주나
#   4) 로그인·데이터가 되는가 (api)
UA='Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36'

echo '=== 1. 스토어 페이지 (로그아웃 상태) ==='
for U in \
  'https://play.google.com/store/apps/details?id=app.massa.hanoi&hl=vi&gl=VN' \
  'https://play.google.com/store/apps/details?id=app.massa.hanoi&hl=ko&gl=KR' \
  'https://apps.apple.com/vn/app/id6804698319' \
  'https://apps.apple.com/kr/app/id6804698319' ; do
  printf '  %-72s %s\n' "$(echo "$U" | cut -c1-72)" \
    "$(curl -s -o /dev/null -w '%{http_code}' --max-time 25 -A "$UA" "$U")"
done

echo ''
echo '=== 2. 앱이 불러오는 화면 ==='
for U in https://app.massaviet.com/ https://massa-seven.vercel.app/ https://www.massaviet.com/ ; do
  printf '  %-40s %s  (%s bytes)\n' "$U" \
    "$(curl -s -o /dev/null -w '%{http_code}' --max-time 25 -A "$UA" "$U")" \
    "$(curl -sL --max-time 25 -A "$UA" "$U" | wc -c)"
done

echo ''
echo '=== 3. 프록시가 VPS 최신을 주는가 (두 쪽 내용이 같아야 한다) ==='
A=$(curl -sL --max-time 25 https://app.massaviet.com/        | md5sum | cut -d' ' -f1)
B=$(curl -sL --max-time 25 https://massa-seven.vercel.app/   | md5sum | cut -d' ' -f1)
printf '  app.massaviet.com    %s\n  vercel 프록시        %s\n' "$A" "$B"
[ "$A" = "$B" ] && echo '  -> 같다 (정상)' || echo '  -> 다르다. 안드로이드 사용자는 옛 화면을 본다'

echo ''
echo '=== 4. assetlinks (이게 깨지면 안드로이드에서 주소창이 뜬다) ==='
printf '  %s\n' "$(curl -s --max-time 20 https://massa-seven.vercel.app/.well-known/assetlinks.json | head -c 200)"

echo ''
echo '=== 5. 로그인·데이터 ==='
KEY=$(grep -E '^ANON_KEY=' /root/massa/.env | cut -d= -f2-)
printf '  auth settings   %s\n' "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 -H "apikey: $KEY" https://api.moahagwon.com/auth/v1/settings)"
printf '  providers 조회  %s\n' "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 -H "apikey: $KEY" 'https://api.moahagwon.com/rest/v1/providers?select=id&limit=1')"
