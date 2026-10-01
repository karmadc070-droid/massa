#!/bin/sh
# 버튼이 있어도 서버가 redirect_to 를 거부하면 로그인이 안 된다.
# /auth/v1/authorize 의 Location 이 accounts.google.com 으로 가는지 본다. 이게 실제 통과 여부다.
KEY=$(grep -E '^ANON_KEY=' /root/massa/.env | cut -d= -f2-)
for U in "https://admin.massaviet.com/" "https://admin.moahagwon.com/"; do
  L=$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 20 -H "apikey: $KEY" \
      "https://api.moahagwon.com/auth/v1/authorize?provider=google&redirect_to=$U")
  case "$L" in
    *accounts.google.com*) R='구글로 넘어감 (정상)' ;;
    *error*|*invalid*)     R="거부됨 -> $L" ;;
    *)                     R="예상 밖 -> $L" ;;
  esac
  printf '  %-34s %s\n' "$U" "$R"
done
