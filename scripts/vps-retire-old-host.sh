#!/bin/bash
# 옛 주소 massa.moahagwon.com 을 app.massaviet.com 으로 넘긴다.
#
# 왜 지금 해도 되나 — 최근 48시간 실제 접속 0건이다.
# 7일 치에 보이던 65건은 전부 인증서 갱신 로그였고, vercel 쪽 19건도 48시간 내에는 0건이다.
# (Play 1.1.0 이 출시되면서 옛 안드로이드 앱이 새 주소로 넘어갔다.)
#
# 지우지 않고 '넘긴다'. 혹시 옛 링크를 눌러 들어오는 사람이 있어도 죽은 페이지 대신
# 제대로 된 앱으로 간다. 되돌리려면 Caddyfile 백업을 쓰면 된다.
set -e

F=/root/Caddyfile
cp "$F" "$F.bak.$(date +%s)"
echo "백업: $F.bak.*"

python3 - "$F" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()

if 'massa-old-retired' in s:
    print('이미 넘겨 둠 — 아무것도 안 한다'); raise SystemExit(0)

# massa.moahagwon.com 블록을 통째로 찾아 리다이렉트로 바꾼다
m = re.search(r'\nmassa\.moahagwon\.com\s*\{.*?\n\}\n', s, re.S)
if not m:
    print('★ massa.moahagwon.com 블록을 못 찾았다 — 중단'); raise SystemExit(1)

new = """
# massa-old-retired — 옛 주소. 2026-10-07 기준 실제 접속 0건이라 새 주소로 넘긴다.
massa.moahagwon.com {
    redir https://app.massaviet.com{uri} permanent
}
"""
s = s[:m.start()] + new + s[m.end():]
open(p, 'w', encoding='utf-8').write(s)
print('Caddyfile 수정함')
PY

echo ''
echo '=== 문법 검사 ==='
C=$(docker ps --format '{{.Names}}' | grep -i caddy | head -1)
docker exec "$C" caddy validate --config /etc/caddy/Caddyfile 2>&1 | tail -2

echo ''
echo '=== reload ==='
docker exec "$C" caddy reload --config /etc/caddy/Caddyfile 2>/dev/null || docker restart "$C"
sleep 6

echo ''
echo '=== 확인 ==='
printf '  옛 주소        %s -> %s\n' \
  "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://massa.moahagwon.com/)" \
  "$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 20 https://massa.moahagwon.com/)"
printf '  옛 주소 하위   %s -> %s\n' \
  "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://massa.moahagwon.com/privacy.html)" \
  "$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 20 https://massa.moahagwon.com/privacy.html)"
printf '  새 주소        %s\n' "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://app.massaviet.com/)"
printf '  운영 콘솔      %s\n' "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://admin.massaviet.com/)"
printf '  API            %s  (401 이 정상)\n' "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://api.moahagwon.com/auth/v1/health)"
printf '  소개 사이트    %s\n' "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://massaviet.com/)"
