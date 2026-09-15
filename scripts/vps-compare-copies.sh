#!/bin/sh
# 앱 사본이 여럿이다. 어느 것이 낡았는지 본다.
#   /srv/massa-app  = app.massaviet.com  (새 정식 주소)
#   /srv/massa-web  = massa.moahagwon.com (예전부터 있던 것)
echo '=== 파일 날짜 ==='
ls -la --time-style=+%Y-%m-%d /srv/massa-app/index.html /srv/massa-web/index.html 2>/dev/null | sed 's/^/  /'

echo ''
echo '=== 기능이 들어 있는가 (0 이면 낡은 것) ==='
for f in /srv/massa-app/index.html /srv/massa-web/index.html; do
  [ -f "$f" ] || { echo "  $f 없음"; continue; }
  printf '  %-28s ' "$f"
  printf '개인가격=%s ' "$(grep -c 'provPrice' "$f")"
  printf '사진확대=%s ' "$(grep -c 'openLightbox' "$f")"
  printf '지도검색=%s ' "$(grep -c 'openPlaceSheet' "$f")"
  printf '실제거리=%s\n' "$(grep -c 'haversineKm' "$f")"
done

echo ''
echo '=== 재설정 메일이 어디로 보내는가 ==='
for f in /srv/massa-app/index.html /srv/massa-web/index.html; do
  [ -f "$f" ] || continue
  printf '  %-28s ' "$f"
  grep -oE "RESET_REDIRECT = '[^']+'" "$f" | head -1
done
