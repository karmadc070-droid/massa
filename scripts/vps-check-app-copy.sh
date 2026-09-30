#!/bin/sh
# 앱 화면(index.html)의 문구 교체가 세 주소 모두에 반영됐는지 본다.
# massa-seven.vercel.app 은 프록시라 VPS 와 같은 내용을 줘야 한다 — 다르면 프록시가 깨진 것이다.
for U in https://app.massaviet.com/ https://massa.moahagwon.com/ https://massa-seven.vercel.app/; do
  B=$(curl -s --max-time 25 "$U")
  printf '=== %s ===\n' "$U"
  printf '  제목        %s\n' "$(printf '%s' "$B" | grep -o '<title>[^<]*' | sed 's/<title>//' | head -1)"
  printf '  베트남 설명 %s (1 이어야 한다)\n' "$(printf '%s' "$B" | grep -c 'content="베트남 집·호텔로')"
  printf '  옛 3단계 검증 문구 %s (0 이어야 한다)\n' "$(printf '%s' "$B" | grep -c '3단계 검증을 통과한')"
  printf '  새 인증 안내 %s (1 이상)\n' "$(printf '%s' "$B" | grep -c '신분증과 자격 서류 확인이 끝난')"
  printf '  아직 후기 없음 %s (3 이어야 한다)\n' "$(printf '%s' "$B" | grep -c '아직 후기 없음')"
  echo ''
done
