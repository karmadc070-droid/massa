#!/bin/bash
# 소셜 아이콘 SVG 를 simple-icons 에서 받아 한 줄씩 찍는다.
# 내 기억으로 로고를 그리지 않기 위해서다 - 받아서 쓴다.
# 받은 결과는 site-src/social_icons.py 로 저장한다.
for n in naver blogger instagram threads facebook youtube tiktok tistory; do
  u="https://cdn.jsdelivr.net/npm/simple-icons@13/icons/$n.svg"
  body=$(curl -s --max-time 20 "$u")
  if [ -z "$body" ]; then
    echo "$n|MISSING"
  else
    # viewBox 와 path d 만 뽑는다
    d=$(printf '%s' "$body" | grep -o 'd="[^"]*"' | head -1 | sed 's/^d="//; s/"$//')
    echo "$n|$d"
  fi
done
