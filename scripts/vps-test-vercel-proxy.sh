#!/bin/sh
# Vercel 프록시 미리보기를 검증한다. 프로덕션에 붙이기 전에 여기서 다 확인한다.
# 합격 조건 — 200 이고, 리다이렉트가 아니며(주소가 바뀌면 TWA 와 로그인이 깨진다),
#             새 화면 문구가 있고, assetlinks 지문이 그대로여야 한다.
H="${1:?미리보기 호스트를 인자로 넘겨라}"

echo "=== 대상: https://$H ==="

echo '--- 1. 첫 화면 (리다이렉트 없이 200 이어야 한다) ---'
curl -s -o /tmp/v.html -w '  상태:%{http_code}  리다이렉트:%{num_redirects}  최종주소:%{url_effective}\n' --max-time 30 "https://$H/"
printf '  크기:%s bytes\n' "$(wc -c < /tmp/v.html)"
printf '  새 문구(아직 후기 없음):%s\n' "$(grep -c '아직 후기 없음' /tmp/v.html || true)"
printf '  앱 확인(massa):%s\n' "$(grep -c 'massa' /tmp/v.html || true)"

echo '--- 2. assetlinks (TWA 가 여기 걸린다) ---'
curl -s -o /tmp/a.json -w '  상태:%{http_code}\n' --max-time 20 "https://$H/.well-known/assetlinks.json"
printf '  지문 2개 다 있나: %s\n' "$(grep -c '7B:AC:10:B2\|05:7B:16:B3' /tmp/a.json || true)"
cat /tmp/a.json | head -c 200; echo ''

echo '--- 3. 하위 경로도 프록시되나 ---'
for P in reset.html privacy.html terms.html delete-account.html pay-start.html manifest.webmanifest sw.js; do
  printf '  %-24s %s\n' "$P" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "https://$H/$P")"
done

echo '--- 4. 비밀이 새지 않나 (전부 404 여야 한다) ---'
for P in .env config.example.js android-package/signing.keystore; do
  printf '  %-34s %s\n' "$P" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "https://$H/$P")"
done
