#!/bin/sh
# PLAY_LIVE 를 켠 뒤 확인한다.
# 기대 — 3개 언어 download 페이지에 play.google.com 설치 버튼이 있고,
#        '안드로이드는 준비 중' 안내 섹션이 사라졌고, jsonld sameAs 에 PLAY 주소가 들어갔어야 한다.
for U in https://massaviet.com/download.html https://massaviet.com/en/download.html https://massaviet.com/vi/download.html; do
  B=$(curl -s --max-time 25 "$U")
  printf '=== %s ===\n' "$U"
  printf '  설치 버튼(play.google.com)  %s\n' "$(printf '%s' "$B" | grep -c 'play.google.com/store/apps/details')"
  printf '  준비 중 안내가 남았나       %s (0 이어야 한다)\n' "$(printf '%s' "$B" | grep -c '준비 중입니다\|coming to Google Play\|sắp có trên Google Play\|Chuẩn bị')"
  printf '  회색 store off 박스         %s (0 이어야 한다)\n' "$(printf '%s' "$B" | grep -c 'store off')"
done

echo ''
echo '=== 첫 화면 jsonld sameAs ==='
curl -s --max-time 25 https://massaviet.com/ | grep -o '"sameAs":[^]]*]' | head -1 | sed 's/^/  /'
