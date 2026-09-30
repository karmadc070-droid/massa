#!/bin/sh
# 배포된 사이트에서 하노이 → 베트남 교체가 의도대로 됐는지 본다.
# 기대 — 제목·히어로에는 베트남만. '현재 하노이 운영' 같은 사실 문구는 남아 있어야 한다(0 이면 오히려 잘못).
for U in https://massaviet.com/ https://massaviet.com/en/ https://massaviet.com/vi/; do
  B=$(curl -s --max-time 25 "$U")
  printf '=== %s ===\n' "$U"
  printf '  제목   %s\n' "$(printf '%s' "$B" | grep -o '<title>[^<]*' | sed 's/<title>//' | head -1)"
  printf '  히어로 %s\n' "$(printf '%s' "$B" | grep -o 'class="kicker"[^<]*<[^>]*>[^<]*' | head -1 | sed 's/.*>//')"
  printf '  베트남 표기 %s 곳 / 하노이 표기 %s 곳\n' \
    "$(printf '%s' "$B" | grep -o '베트남\|Vietnam\|Việt Nam' | wc -l)" \
    "$(printf '%s' "$B" | grep -o '하노이\|Hanoi\|Hà Nội' | wc -l)"
  printf '  남아 있어야 할 사실 문구: %s\n' "$(printf '%s' "$B" | grep -o '현재 하노이[^<]*\|Currently operating in Hanoi\|hiện hoạt động tại Hà Nội\|Hiện đang hoạt động tại Hà Nội' | head -1)"
  echo ''
done
