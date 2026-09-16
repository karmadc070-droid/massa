#!/bin/sh
# 색인이 안 된 두 페이지에 실제 결함이 있는지 본다.
# '발견됨 - 현재 색인이 생성되지 않음' 은 보통 구글 쪽 크롤 예산 문제지만,
# 우리 쪽 결함(중복 제목·얇은 본문·잘못된 canonical)일 수도 있다. 확인하고 판단한다.
set -u
for u in /en/terms.html /vi/about.html /terms.html /about.html /en/about.html /vi/terms.html; do
  B=$(curl -s "https://massaviet.com$u")
  printf '=== %s ===\n' "$u"
  printf '  상태     %s\n' "$(curl -s -o /dev/null -w '%{http_code}' "https://massaviet.com$u")"
  printf '  제목     %s\n' "$(printf '%s' "$B" | grep -o '<title>[^<]*' | sed 's/<title>//' | head -1)"
  printf '  설명     %s\n' "$(printf '%s' "$B" | grep -o 'name="description" content="[^"]*' | sed 's/.*content="//' | cut -c1-70)"
  printf '  canonical %s\n' "$(printf '%s' "$B" | grep -o 'rel="canonical" href="[^"]*' | sed 's/.*href="//')"
  printf '  본문글자 %s\n' "$(printf '%s' "$B" | sed -e 's/<script[^>]*>.*<\/script>//g' -e 's/<[^>]*>/ /g' | tr -s ' ' | wc -c)"
  printf '  noindex  %s\n' "$(printf '%s' "$B" | grep -c 'noindex')"
  echo ''
done

echo '=== robots.txt 가 막고 있나 ==='
curl -s https://massaviet.com/robots.txt | sed 's/^/  /'

echo ''
echo '=== 사이트맵에 두 주소가 들어 있나 ==='
S=$(curl -s https://massaviet.com/sitemap.xml)
for u in /en/terms.html /vi/about.html; do
  printf '  %-22s %s\n' "$u" "$(printf '%s' "$S" | grep -c "massaviet.com$u")"
done
