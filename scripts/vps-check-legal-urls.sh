#!/bin/sh
# 스토어에 등록된 법적 URL 이 vercel 을 가리키고 있다. 옮길 곳이 살아 있는지 먼저 본다.
#
# 이게 왜 중요한가: 개인정보처리방침 URL 은 구글 플레이가 **반드시 열려야 한다**고 요구한다.
# vercel 을 끄는 순간 그 주소가 404 가 되고 앱이 제재를 받는다.
# 즉 "Vercel 끄기" 전에 이 URL 들을 반드시 먼저 옮겨야 한다.

echo '=== 지금 스토어에 등록된 주소 (옛 주소) ==='
for p in privacy.html terms.html delete-account.html ''; do
  printf '  %-46s ' "https://massa-seven.vercel.app/$p"
  curl -s -o /dev/null -w '%{http_code}\n' --max-time 15 "https://massa-seven.vercel.app/$p"
done

echo ''
echo '=== 옮길 후보 1 — 소개 사이트 (공개 문서용) ==='
for p in privacy.html terms.html delete-account.html ''; do
  printf '  %-46s ' "https://massaviet.com/$p"
  curl -s -o /dev/null -w '%{http_code}\n' --max-time 15 "https://massaviet.com/$p"
done

echo ''
echo '=== 옮길 후보 2 — 앱 주소 ==='
for p in privacy.html terms.html delete-account.html; do
  printf '  %-46s ' "https://app.massaviet.com/$p"
  curl -s -o /dev/null -w '%{http_code}\n' --max-time 15 "https://app.massaviet.com/$p"
done
