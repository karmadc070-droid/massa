#!/bin/sh
# 고객 앱을 배포하고, 필수 항목 표시가 실제로 반영됐는지 확인한다.
sh /root/vps-deploy-web.sh 2>&1 | tail -5
echo '--- 배포된 파일 확인 ---'
for f in /srv/massa-web/index.html /srv/massa-admin/index.html; do
  printf '%-30s 별표=%s  검사함수=%s  무명대체값=%s\n' "$f" \
    "$(grep -c -F 'class="req"' "$f")" \
    "$(grep -c -F 'apMissingFields' "$f")" \
    "$(grep -c -F "|| '무명'" "$f")"
done
