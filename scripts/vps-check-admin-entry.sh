#!/bin/bash
# massa 에 이미 있는 관리자 진입점을 확인한다. 읽기만 한다.
echo '=== 접속 확인 ==='
for u in https://massaviet.com/admin/ https://massaviet.com/admin \
         https://admin.massaviet.com/ https://www.emoiviet.com/admin; do
  printf '  %-40s %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$u")"
done

echo ''
echo '=== 배포된 파일 ==='
echo '  /srv/massaviet-web/admin/'
ls -la /srv/massaviet-web/admin/ 2>/dev/null | tail -n +2 | sed 's/^/    /' || echo '    (없음)'
echo '  /srv/massa-admin/'
ls -la /srv/massa-admin/ 2>/dev/null | tail -n +2 | head -5 | sed 's/^/    /' || echo '    (없음)'

echo ''
echo '=== Caddy 에서 massaviet /admin 을 어떻게 다루나 ==='
grep -n -A 14 '^massaviet.com' /root/Caddyfile | sed 's/^/  /'

echo ''
echo '=== emoi 는 /admin 을 어떻게 막고 있나 (참고) ==='
grep -n -B 2 -A 12 'adminpath' /root/Caddyfile | sed 's/^/  /'
