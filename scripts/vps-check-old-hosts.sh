#!/bin/sh
# 옛 주소를 닫아도 되는지, api 도메인을 옮길 준비가 됐는지 본다. 읽기만 한다.
#
# 닫기 전에 알아야 할 것은 하나다 — 아직 거기로 들어오는 사람이 있는가.
# 로그를 보지 않고 닫으면 옛 앱을 쓰는 손님이 그대로 끊긴다.

echo '=== 1. Caddy 접근 로그가 어디에 있나 ==='
grep -n 'log\|output file' /root/Caddyfile | head -10
ls -la /var/log/caddy 2>/dev/null | head -8 || echo '  /var/log/caddy 없음'
C=$(docker ps --format '{{.Names}}' | grep -i caddy | head -1)
echo "  caddy 컨테이너: $C"

echo ''
echo '=== 2. 최근 로그에서 옛 주소로 들어온 요청 (컨테이너 stdout) ==='
docker logs --since 168h "$C" 2>&1 | grep -oE '"host":"[^"]+"' | sort | uniq -c | sort -rn | head -15 \
  || echo '  (JSON 로그가 아님 — 아래 평문으로 다시 본다)'

echo ''
echo '=== 3. 평문 로그일 때 ==='
docker logs --since 168h "$C" 2>&1 | grep -oE 'massa-seven\.vercel\.app|massa\.moahagwon\.com|app\.massaviet\.com|api\.moahagwon\.com' \
  | sort | uniq -c | sort -rn | head

echo ''
echo '=== 4. 지금 열려 있는 주소들 ==='
for u in https://massa-seven.vercel.app/ https://massa.moahagwon.com/ https://app.massaviet.com/ \
         https://api.moahagwon.com/auth/v1/health https://api.massaviet.com/auth/v1/health; do
  printf '  %-48s %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "$u")"
done

echo ''
echo '=== 5. massaviet.com DNS 가 어디를 가리키나 (api 를 붙일 수 있나) ==='
for h in massaviet.com app.massaviet.com admin.massaviet.com api.massaviet.com api.moahagwon.com; do
  printf '  %-24s %s\n' "$h" "$(getent hosts "$h" | awk '{print $1}' | tr '\n' ' ')"
done
echo '  ※ 이 서버: 141.164.46.88'

echo ''
echo '=== 6. 앱이 바라보는 주소 (배포본 기준) ==='
grep -o "SUPABASE_URL = '[^']*'" /srv/massa-app/index.html | head -1 | sed 's/^/  /'
grep -c 'api.moahagwon.com' /srv/massa-app/index.html | sed 's/^/  index.html 안에서 등장 횟수: /'
