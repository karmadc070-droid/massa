#!/bin/bash
# iOS 앱이 어느 나라 App Store 에 떠 있는지 공개 조회 API 로 확인한다.
# App Store Connect 로그인 없이 '실제로 보이는가' 를 본다.
# resultCount 가 1 이면 그 나라 스토어에 있는 것이고, 0 이면 없다.
APPID=6804698319
echo "앱 ID $APPID"
echo
for c in vn kr us jp cn tw hk au gb de fr sg th my ph id in ru ca nz; do
  n=$(curl -s --max-time 15 "https://itunes.apple.com/lookup?id=$APPID&country=$c" \
      | grep -o '"resultCount":[0-9]*' | head -1 | cut -d: -f2)
  [ "$n" = "1" ] && r="있음" || r="없음"
  printf '  %-4s %s\n' "$c" "$r"
done
