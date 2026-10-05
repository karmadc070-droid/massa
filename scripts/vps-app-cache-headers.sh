#!/bin/bash
# app.massaviet.com 의 정적 파일에 캐시 헤더를 준다.
#
# 지금은 헤더가 아예 없어서 브라우저가 알아서 판단한다 — 아이콘·사진까지 매번 다시 받는다.
# 규칙은 두 가지뿐이다.
#   · 그림·폰트  → 1년. 내용이 바뀌면 파일 이름이나 ?v= 가 바뀌니 오래 잡아도 안전하다
#   · HTML       → no-cache. **여기가 앱 본체다.** 오래 잡으면 고쳐도 손님에게 안 간다.
#                  no-cache 는 '쓰지 말라' 가 아니라 '쓸 때마다 바뀌었는지 물어보라' 다
# sw.js·manifest·assetlinks 는 이미 no-cache 로 잡혀 있다. 그대로 둔다.
set -e

F=/root/Caddyfile
cp "$F" "$F.bak.$(date +%s)"

if grep -q 'massa-app-static-cache' "$F"; then
  echo '이미 적용돼 있음 — 아무것도 안 한다'
else
  python3 - "$F" <<'PY'
import re, sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()

# app.massaviet.com 블록 안, 기존 @nocache 줄 바로 앞에 끼워 넣는다.
anchor = '    @nocache path /sw.js /manifest.webmanifest /.well-known/*'
add = '''    # massa-app-static-cache
    @static path *.png *.jpg *.jpeg *.webp *.svg *.ico *.woff2 *.woff
    header @static Cache-Control "public, max-age=31536000, immutable"
    # 앱 본체. 오래 잡으면 고친 게 손님에게 안 간다 — 매번 바뀌었는지만 묻게 한다.
    @html path / *.html
    header @html Cache-Control "no-cache"
'''
if anchor not in s:
    print('★ app.massaviet.com 블록의 @nocache 줄을 못 찾았다 — 중단')
    raise SystemExit(1)
s = s.replace(anchor, add + anchor, 1)
open(p, 'w', encoding='utf-8').write(s)
print('Caddyfile 수정함')
PY
fi

echo ''
echo '=== 문법 검사 ==='
C=$(docker ps --format '{{.Names}}' | grep -i caddy | head -1)
docker exec "$C" caddy validate --config /etc/caddy/Caddyfile 2>&1 | tail -3 \
  || docker exec "$C" caddy validate --config /root/Caddyfile 2>&1 | tail -3

echo ''
echo '=== reload ==='
docker exec "$C" caddy reload --config /etc/caddy/Caddyfile 2>/dev/null \
  || docker exec "$C" caddy reload --config /root/Caddyfile 2>/dev/null \
  || { echo 'reload 실패 — 재시작'; docker restart "$C"; sleep 8; }

echo ''
echo '=== 확인 ==='
for p in "" index.html icon-192.png maskable-512.png sw.js manifest.webmanifest; do
  printf '  %-26s %s\n' "/$p" \
    "$(curl -s -o /dev/null -D- --max-time 20 "https://app.massaviet.com/$p" | grep -i '^cache-control' | tr -d '\r')"
done
echo '  ※ 그림은 max-age=31536000, HTML 과 sw.js 는 no-cache 여야 한다'
