#!/bin/bash
# Caddyfile 이 문법 오류로 깨져 있다. 지금은 메모리에 있는 옛 설정으로 버티는 중이라
# 서비스는 정상이지만, **서버가 재시작되면 Caddy 가 아예 안 뜬다.** massa 뿐 아니라
# 이 서버의 모든 사이트가 같이 죽는다. 그래서 먼저 고친다.
#
# 오류 — www.emoiviet.com 블록(177행) 의 `handle /admin /admin/*`.
# Caddy 의 handle 은 매처를 하나만 받는다. 두 개를 쓰려면 이름 붙인 매처로 묶어야 한다.
# massa 작업과는 무관한 다른 프로젝트 설정이고, 10-06 이후 누군가 손댄 것으로 보인다.
# (10-06 00:44 백업은 문법 통과, 그 이후 판부터 깨져 있다.)
set -e

echo '=== 0. 깨진 줄 ==='
grep -n 'handle /admin /admin/\*' /root/Caddyfile | sed 's/^/  /' || echo '  해당 줄 없음'

echo ''
echo '=== 1. 이름 붙인 매처로 고치기 ==='
cp /root/Caddyfile "/root/Caddyfile.broken.$(date +%s)"
python3 - /root/Caddyfile <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
old = 'handle /admin /admin/* {'
new = ('@adminpath path /admin /admin/*\n    handle @adminpath {')
n = s.count(old)
if n == 0:
    print('  고칠 줄이 없다 (이미 고쳐졌거나 형태가 다르다)')
else:
    s = s.replace(old, new)
    open(p, 'w', encoding='utf-8').write(s)
    print(f'  {n}곳 고침')
PY

echo ''
echo '=== 2. 문법 검사 ==='
docker exec -i caddy sh -c 'cat > /tmp/t' < /root/Caddyfile
if docker exec caddy caddy validate --config /tmp/t --adapter caddyfile >/dev/null 2>&1; then
  echo '  통과'
else
  echo '  ★ 아직 오류가 있다 — 적용하지 않는다'
  docker exec caddy caddy validate --config /tmp/t --adapter caddyfile 2>&1 | tail -2 | sed 's/^/  /'
  exit 1
fi

echo ''
echo '=== 3. massa 쪽 설정이 들어 있는지 (적용 전 마지막 점검) ==='
for k in 'massa-old-retired' 'massa-app-static-cache' 'app.massaviet.com' 'admin.massaviet.com' 'api.moahagwon.com' 'www.emoiviet.com'; do
  printf '  %-26s %s\n' "$k" "$(grep -c "$k" /root/Caddyfile)"
done

echo ''
echo '=== 4. 적용 ==='
docker exec -i caddy sh -c 'cat > /etc/caddy/Caddyfile' < /root/Caddyfile
docker exec caddy caddy reload --config /etc/caddy/Caddyfile 2>&1 | tail -1
sleep 6

echo ''
echo '=== 5. 확인 — massa ==='
printf '  옛 주소        %s -> %s\n' \
  "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://massa.moahagwon.com/)" \
  "$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 20 https://massa.moahagwon.com/)"
for u in https://app.massaviet.com/ https://admin.massaviet.com/ https://massaviet.com/ \
         https://massaviet.com/vi/ https://app.massaviet.com/.well-known/assetlinks.json; do
  printf '  %-54s %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$u")"
done
printf '  %-54s %s  (401 정상)\n' 'https://api.moahagwon.com/auth/v1/health' \
  "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://api.moahagwon.com/auth/v1/health)"
printf '  아이콘 캐시헤더 %s\n' \
  "$(curl -s -o /dev/null -D- --max-time 20 https://app.massaviet.com/icon-192.png | grep -i '^cache-control' | tr -d '\r')"

echo ''
echo '=== 6. 확인 — 같은 서버의 다른 사이트 (내가 건드린 블록) ==='
for u in https://www.emoiviet.com/ https://www.emoiviet.com/admin; do
  printf '  %-40s %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$u")"
done
echo '  ※ /admin 은 로그인 전이라 302(구글 로그인) 또는 401 이면 정상이다'
