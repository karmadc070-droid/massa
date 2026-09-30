#!/bin/sh
# GoTrue 허용목록과 SITE_URL 을 본다. 값 자체는 비밀이 아니다(공개 주소 목록).
# 새 운영 콘솔 주소를 넣기 전에 지금 무엇이 들어 있는지 확인한다.
echo '=== SITE_URL ==='
grep -E '^SITE_URL=' /root/massa/.env | sed 's/^/  /'
echo ''
echo '=== ADDITIONAL_REDIRECT_URLS (한 줄씩) ==='
grep -E '^ADDITIONAL_REDIRECT_URLS=' /root/massa/.env | sed 's/^ADDITIONAL_REDIRECT_URLS=//' | tr ',' '\n' | sed 's/^/  /'
