#!/bin/sh
# Vercel 프록시가 VPS 최신을 안 주면 안드로이드 사용자는 옛 화면을 본다.
# 고친 문구가 양쪽에 다 있는지, 캐시 헤더가 뭘 말하는지 본다.
MARK='아직 제휴한 매장이 아니라서'
for U in https://app.massaviet.com/ https://massa-seven.vercel.app/ ; do
  echo "--- $U"
  printf '  새 문구      %s\n' "$(curl -sL --max-time 25 "$U" | grep -c "$MARK")"
  printf '  크기         %s\n' "$(curl -sL --max-time 25 "$U" | wc -c)"
  curl -sI --max-time 25 "$U" | grep -iE '^(age|cache-control|x-vercel-cache|etag|last-modified):' | sed 's/^/  /'
done
echo ''
echo '--- 캐시 우회해서 다시 ---'
printf '  vercel ?cb   %s\n' "$(curl -sL --max-time 25 "https://massa-seven.vercel.app/?cb=$(date +%s)" | grep -c "$MARK")"
