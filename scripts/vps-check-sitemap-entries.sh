#!/bin/sh
# GSC 가 vi/about.html 을 "사이트맵에서 못 봤다"고 한다. 사이트맵에 <loc> 으로 들어 있는지 본다.
# hreflang 대체 링크로만 들어 있고 <loc> 이 없으면 구글은 그 주소를 사이트맵 등록으로 치지 않는다.
S=$(curl -s https://massaviet.com/sitemap.xml)

echo '=== <loc> 으로 등록된 주소 (구글이 사이트맵 항목으로 세는 것) ==='
printf '%s' "$S" | grep -o '<loc>[^<]*</loc>' | sed 's/<[^>]*>//g' | sed 's/^/  /'

echo ''
echo '=== 개수 ==='
printf '  <loc> 총 개수: %s\n' "$(printf '%s' "$S" | grep -c '<loc>')"
printf '  vi/about.html 이 <loc> 에 있나: %s\n' "$(printf '%s' "$S" | grep -o '<loc>[^<]*</loc>' | grep -c 'vi/about.html')"
printf '  en/terms.html 이 <loc> 에 있나: %s\n' "$(printf '%s' "$S" | grep -o '<loc>[^<]*</loc>' | grep -c 'en/terms.html')"
