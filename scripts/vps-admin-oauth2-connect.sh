#!/bin/bash
# massaviet.com/admin 에 문지기를 연결한다 (2단계 — 문을 잠근다).
#
# 전제 — 구글 클라우드 콘솔의 OAuth 클라이언트에
#        https://massaviet.com/oauth2/callback 가 승인된 리디렉션 URI 로 들어가 있어야 한다.
#        안 넣고 돌리면 사장님도 못 들어간다. 그래서 먼저 확인하고 시작한다.
#
# 되돌리기 — 맨 아래 안내대로 백업을 되돌리고 reload 하면 즉시 원복된다.
set -e

echo '=== 0. 문지기가 살아 있나 ==='
docker ps --format '{{.Names}}\t{{.Status}}' | grep massa-oauth2-proxy \
  || { echo '문지기가 없다 — vps-admin-oauth2-setup.sh 를 먼저 돌릴 것'; exit 1; }
curl -s -o /dev/null -w '  /oauth2/auth HTTP %{http_code} (401 이어야 한다)\n' http://127.0.0.1:4181/oauth2/auth

F=/root/Caddyfile
BK="$F.bak.$(date +%s)"
cp "$F" "$BK"
echo "되돌릴 백업: $BK"

python3 - <<'PY'
F = '/root/Caddyfile'
s = open(F, encoding='utf-8').read()

old = """    @adminpath path /admin /admin/*
    @notadmin not path /admin /admin/*"""
new = """    @adminpath path /admin /admin/*
    @notadmin not path /admin /admin/*

    # 관리자 화면은 구글 로그인을 통과한 사람만 '열 수' 있다 (2026-10-10).
    # 데이터는 원래 DB 가 막고 있었지만, 화면 자체는 누구나 열렸다. 그것부터 막는다.
    # 문지기(oauth2-proxy)는 127.0.0.1:4181 에만 묶여 있어 밖에서 직접 못 부른다.
    reverse_proxy /oauth2/* localhost:4181
    forward_auth @adminpath localhost:4181 {
        uri /oauth2/auth
        copy_headers X-Auth-Request-User X-Auth-Request-Email

        # 통과 못 하면 401 이 온다. 구글 로그인으로 보내고 원래 주소로 되돌린다.
        @error status 4xx
        handle_response @error {
            redir * /oauth2/sign_in?rd={scheme}://{host}{uri}
        }
    }"""
assert s.count(old) == 1, 'massaviet.com 의 @adminpath 를 못 찾았다'
open(F, 'w', encoding='utf-8').write(s.replace(old, new))
print('Caddyfile 고쳤다')
PY

echo '=== 1. 문법 검사 ==='
docker exec caddy caddy validate --config /etc/caddy/Caddyfile 2>&1 | tail -1
echo '=== 2. 적용 ==='
docker exec caddy caddy reload --config /etc/caddy/Caddyfile >/dev/null 2>&1 && echo reloaded
sleep 3

echo ''
echo '=== 3. 로그인 없이 열리나 (302 로 구글에 보내야 한다) ==='
for u in /admin/ /admin/console/ /admin/console/reset.html; do
  printf '  %-28s %s -> %s\n' "$u" \
    "$(curl -s -o /dev/null -w '%{http_code}' "https://massaviet.com$u")" \
    "$(curl -s -o /dev/null -w '%{redirect_url}' "https://massaviet.com$u" | head -c 70)"
done
echo ''
echo '=== 4. 공개 페이지는 그대로인가 (전부 200 이어야 한다) ==='
for u in / /services.html /partner.html /guide.html /faq.html /vi/ /en/ /robots.txt /sitemap.xml; do
  printf '  %-16s %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' "https://massaviet.com$u")"
done
echo ''
echo '=== 5. 앱·API 는 영향 없나 ==='
printf '  app        %s\n' "$(curl -s -o /dev/null -w '%{http_code}' https://app.massaviet.com/)"
printf '  api        %s (401 이 정상)\n' "$(curl -s -o /dev/null -w '%{http_code}' https://api.moahagwon.com/auth/v1/settings)"
echo ''
echo "=== 되돌리려면 ==="
echo "  cp $BK /root/Caddyfile && docker exec caddy caddy reload --config /etc/caddy/Caddyfile"
