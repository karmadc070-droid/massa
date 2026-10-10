#!/bin/bash
# 지표 주소를 massaviet.com/admin 하나로 모은다.
#
# 무엇을 바꾸나
#   massaviet.com/admin        → 지금은 301. 앞으로는 여기서 바로 보여 준다.
#   admin.massaviet.com/metrics → 앞으로는 301 로 위로 보낸다 (북마크·예전 링크 보호).
#
# 왜 되돌려도 되나 — 파일은 이미 /srv/massaviet-web/admin/index.html 에 있고
#   robots.txt 에 Disallow: /admin/ 이 들어 있고 sitemap 에도 없다. 막는 게 없다.
#
# 다만 admin.massaviet.com 에는 있고 massaviet.com 에는 없던 보호가 셋이다.
# 주소만 옮기고 이걸 빼먹으면 관리자 화면이 공개 도메인에서 맨몸이 된다.
#   1) X-Robots-Tag noindex   — robots.txt 는 '크롤링하지 마라', 이건 '색인하지 마라' 다
#   2) X-Frame-Options DENY   — 남의 페이지 안에 끼워 넣고 클릭을 가로채는 걸 막는다
#   3) Cache-Control no-store — 공개 블록은 max-age=600 이다. 로그인한 관리자 화면을
#                               10분 공개 캐시에 두면 안 된다
set -e
F=/root/Caddyfile
cp "$F" "$F.bak.$(date +%s)"

python3 - <<'PY'
F = '/root/Caddyfile'
s = open(F, encoding='utf-8').read()

old = """    # 관리자는 admin.massaviet.com 하나로 모았다 (2026-10-10). 지표도 그 아래로 옮겼다.
    # ?code= 같은 질의가 붙어 올 수 있다. 떨구면 로그인이 조용히 끝나지 않는다.
    redir /admin* https://admin.massaviet.com/metrics/?{query} permanent
    file_server"""
new = """    # 지표는 massaviet.com/admin 하나로 모았다 (2026-10-10). 주소가 둘이면 둘 다 썩는다.
    # 공개 도메인이라 이 경로만 따로 잠근다 — 색인 금지 · 끼워넣기 금지 · 캐시 금지.
    @adminpath path /admin /admin/*
    @notadmin not path /admin /admin/*
    header @adminpath {
        X-Robots-Tag "noindex, nofollow"
        X-Frame-Options "DENY"
        Cache-Control "no-store"
        Referrer-Policy "no-referrer"
    }
    file_server"""
assert s.count(old) == 1, 'massaviet.com 블록을 못 찾았다'
s = s.replace(old, new)

old2 = """admin.massaviet.com {
    root * /srv/massa-admin
    file_server"""
new2 = """admin.massaviet.com {
    root * /srv/massa-admin
    # 지표는 massaviet.com/admin 으로 모았다. 예전 주소는 지우지 않고 넘겨만 준다.
    # ?code= 가 붙어 올 수 있다. 떨구면 로그인이 조용히 끝나지 않는다.
    redir /metrics /metrics/ permanent
    redir /metrics/* https://massaviet.com/admin/?{query} permanent
    file_server"""
assert s.count(old2) == 1, 'admin.massaviet.com 블록을 못 찾았다'
s = s.replace(old2, new2)

# 캐시와 Referrer 는 공개 경로에만 건다.
# 매처 없는 header 가 나중에 돌아서 @adminpath 의 no-store 를 덮어 버린다. 실제로 덮였다.
old3 = """    header {
        X-Content-Type-Options "nosniff"
        Referrer-Policy "strict-origin-when-cross-origin"
        # 정적 사이트라 길게 잡아도 되지만, 초기에는 짧게 두고 나중에 늘린다
        Cache-Control "public, max-age=600"
    }"""
new3 = """    header {
        X-Content-Type-Options "nosniff"
    }
    header @notadmin {
        Referrer-Policy "strict-origin-when-cross-origin"
        # 정적 사이트라 길게 잡아도 되지만, 초기에는 짧게 두고 나중에 늘린다
        Cache-Control "public, max-age=600"
    }"""
assert s.count(old3) == 1, '전역 header 블록을 못 찾았다'
s = s.replace(old3, new3)

open(F, 'w', encoding='utf-8').write(s)
print('Caddyfile 고쳤다')
PY

C=$(docker ps --format '{{.Names}}' | grep -i caddy | head -1)
# /root/Caddyfile 은 컨테이너의 /etc/caddy/Caddyfile 로 바인드 마운트돼 있다.
# 그래서 docker cp 가 필요 없다 (하면 'device or resource busy' 로 거부당한다).
echo "=== 문법 검사 (통과해야 적용한다) ==="
docker exec "$C" caddy validate --config /etc/caddy/Caddyfile 2>&1 | tail -3

echo "=== 적용 ==="
docker exec "$C" caddy reload --config /etc/caddy/Caddyfile

sleep 3
echo ''
echo '=== 확인 ==='
printf 'massaviet.com/admin/        '
curl -s -o /dev/null -w 'HTTP %{http_code} (200 이어야 한다)\n' https://massaviet.com/admin/
printf 'massaviet.com/admin         '
curl -s -o /dev/null -w 'HTTP %{http_code} → %{redirect_url}\n' https://massaviet.com/admin
printf '옛 주소 /metrics/           '
curl -s -o /dev/null -w 'HTTP %{http_code} → %{redirect_url}\n' https://admin.massaviet.com/metrics/
printf '옛 주소 + ?code=TEST        '
curl -s -o /dev/null -w '→ %{redirect_url}\n' 'https://admin.massaviet.com/metrics/?code=TEST'
printf '운영 콘솔 (그대로)          '
curl -s -o /dev/null -w 'HTTP %{http_code}\n' https://admin.massaviet.com/
echo ''
echo '=== /admin 보호 헤더 ==='
curl -sI https://massaviet.com/admin/ | grep -i "x-robots\|x-frame\|cache-control\|referrer"
echo ''
echo '=== 공개 페이지는 그대로인가 (캐시 600 이어야 한다) ==='
curl -sI https://massaviet.com/ | grep -i "cache-control\|x-frame"
echo ''
echo '=== 지표가 최신인가 ==='
for k in INAPP v_cust drawTraffic mtype; do
  printf '  %-12s %s\n' "$k" "$(curl -s https://massaviet.com/admin/ | grep -c "$k")"
done
