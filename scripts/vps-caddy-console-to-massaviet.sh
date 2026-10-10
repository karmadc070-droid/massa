#!/bin/bash
# 운영 콘솔도 massaviet.com/admin 아래로 모은다.
#
#   massaviet.com/admin/           지표
#   massaviet.com/admin/console/   운영 콘솔   ← 이번에 옮기는 것
#
# 옛 주소는 지우지 않고 넘겨만 준다. 북마크와 예전 재설정 메일 링크가 죽으면 안 된다.
#   admin.massaviet.com/           → massaviet.com/admin/console/
#   admin.massaviet.com/reset.html → massaviet.com/admin/console/reset.html
#   admin.moahagwon.com/*          → (이미 admin.massaviet.com 으로 가니 두 번 거쳐 도착한다)
#
# /admin/* 보안 헤더(@adminpath)는 /admin/console/ 에도 그대로 걸린다. 따로 할 일이 없다.
set -e
F=/root/Caddyfile
cp "$F" "$F.bak.$(date +%s)"

python3 - <<'PY'
F = '/root/Caddyfile'
s = open(F, encoding='utf-8').read()

old = """admin.massaviet.com {
    root * /srv/massa-admin
    # 지표는 massaviet.com/admin 으로 모았다. 예전 주소는 지우지 않고 넘겨만 준다.
    # ?code= 가 붙어 올 수 있다. 떨구면 로그인이 조용히 끝나지 않는다.
    redir /metrics /metrics/ permanent
    redir /metrics/* https://massaviet.com/admin/?{query} permanent
    file_server"""
new = """# 관리자 화면은 massaviet.com/admin 아래 하나로 모았다 (2026-10-10).
# 이 도메인은 이제 넘겨 주기만 한다. 북마크와 예전 재설정 메일 링크를 살려 두려고 남긴다.
# ?code= 나 #access_token 이 붙어 올 수 있다. 질의를 떨구면 로그인이 조용히 끝나지 않는다.
admin.massaviet.com {
    redir /metrics /metrics/ permanent
    redir /metrics/* https://massaviet.com/admin/?{query} permanent
    redir /reset.html https://massaviet.com/admin/console/reset.html?{query} permanent
    redir /* https://massaviet.com/admin/console/?{query} permanent"""
assert s.count(old) == 1, 'admin.massaviet.com 블록을 못 찾았다'
s = s.replace(old, new)

# 남은 꼬리(encode / header / 닫는 괄호)를 정리한다. 이제 파일을 서빙하지 않는다.
tail_old = """    redir /* https://massaviet.com/admin/console/?{query} permanent
    encode gzip
    header {
        X-Frame-Options "DENY"
        X-Content-Type-Options "nosniff"
        Referrer-Policy "strict-origin-when-cross-origin"
    }
}"""
tail_new = """    redir /* https://massaviet.com/admin/console/?{query} permanent
}"""
assert s.count(tail_old) == 1, 'admin.massaviet.com 의 꼬리를 못 찾았다 — 손으로 확인할 것'
s = s.replace(tail_old, tail_new)

open(F, 'w', encoding='utf-8').write(s)
print('Caddyfile 고쳤다')
PY

echo "=== 문법 검사 (통과해야 적용한다) ==="
docker exec caddy caddy validate --config /etc/caddy/Caddyfile 2>&1 | tail -1
echo "=== 적용 ==="
docker exec caddy caddy reload --config /etc/caddy/Caddyfile && echo reloaded
sleep 3

echo ''
echo '=== 새 주소 ==='
printf '  지표              '; curl -s -o /dev/null -w 'HTTP %{http_code} (200)\n' https://massaviet.com/admin/
printf '  운영 콘솔         '; curl -s -o /dev/null -w 'HTTP %{http_code} (200)\n' https://massaviet.com/admin/console/
printf '  콘솔 비번재설정   '; curl -s -o /dev/null -w 'HTTP %{http_code} (200)\n' https://massaviet.com/admin/console/reset.html
echo ''
echo '=== 옛 주소는 전부 넘어가는가 ==='
for u in https://admin.massaviet.com/ https://admin.massaviet.com/reset.html \
         https://admin.massaviet.com/metrics/ https://admin.moahagwon.com/; do
  printf '  %-42s %s -> %s\n' "$u" \
    "$(curl -s -o /dev/null -w '%{http_code}' "$u")" \
    "$(curl -s -o /dev/null -w '%{redirect_url}' "$u")"
done
printf '  %-42s -> %s\n' '옛 콘솔 + ?code=TEST' \
  "$(curl -s -o /dev/null -w '%{redirect_url}' 'https://admin.massaviet.com/?code=TEST')"
echo ''
echo '=== /admin/console/ 도 보안 헤더를 받는가 ==='
curl -sI https://massaviet.com/admin/console/ | grep -i "x-robots\|x-frame\|cache-control\|referrer"
echo ''
echo '=== 공개 페이지는 그대로인가 ==='
for u in / /services.html /partner.html /vi/ /en/; do
  printf '  %-16s %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' "https://massaviet.com$u")"
done
printf '  %-16s ' '캐시'; curl -sI https://massaviet.com/ | grep -i cache-control
