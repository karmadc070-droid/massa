#!/bin/sh
# 배포 뒤 하위 언어 폴더까지 살아 있는지 본다. 예전 배포 스크립트가 폴더를 빼먹은 적이 있다.
echo '=== 응답 코드 ==='
for p in / /en/ /vi/ /download.html /en/download.html /vi/download.html /img/hero.webp /admin/; do
  printf '%-24s ' "$p"
  curl -s -o /dev/null -w '%{http_code}\n' "https://massaviet.com$p"
done

echo ''
echo '=== 다운로드 페이지: 플레이 버튼이 아직 꺼져 있는가 ==='
for p in /download.html /en/download.html /vi/download.html; do
  B=$(curl -s "https://massaviet.com$p")
  printf '%-24s ' "$p"
  echo "$B" | grep -q 'href="https://play.google.com' && printf '설치버튼=켜짐  ' || printf '설치버튼=꺼짐  '
  echo "$B" | grep -q 'store off' && echo '회색박스=있음' || echo '회색박스=없음'
done

echo ''
echo '=== 문구가 스토어 중립으로 바뀌었는가 (about) ==='
curl -s https://massaviet.com/about.html | grep -o '앱 내려받기' | head -1
curl -s https://massaviet.com/en/about.html | grep -o 'Download the app' | head -1
