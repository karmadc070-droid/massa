#!/bin/bash
# massaviet.com/tuyendung -> /vi/partner.html 짧은 주소.
# 영상 끝 화면에서 외워서 치고 들어오는 자리라 짧아야 한다.
# /moijobs 처럼 다른 언어용은 만들지 않는다 - 모집 영상은 베트남어 하나뿐이다.
set -e

echo '=== 0. 이미 있나 ==='
grep -c 'tuyendung' /root/Caddyfile || true

if grep -q 'tuyendung' /root/Caddyfile; then
  echo '  이미 있다 - 중단'
  exit 0
fi

echo ''
echo '=== 1. massaviet.com 블록 안에 한 줄 넣기 ==='
cp /root/Caddyfile "/root/Caddyfile.bak.$(date +%s)"
python3 - /root/Caddyfile <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
key = 'root * /srv/massaviet-web'
n = s.count(key)
if n != 1:
    print(f'  >> 기준 줄이 {n}개다 - 중단'); raise SystemExit(1)
# 블록을 파싱하지 않고 '그 줄 바로 뒤에 한 줄 추가' 만 한다. 중괄호를 건드리지 않는다.
s = s.replace(key, key + '\n    redir /tuyendung /vi/partner.html permanent')
open(p, 'w', encoding='utf-8').write(s)
print('  넣음')
PY

echo ''
echo '=== 2. 문법 검사 (적용 전) ==='
docker exec -i caddy sh -c 'cat > /tmp/t' < /root/Caddyfile
if docker exec caddy caddy validate --config /tmp/t --adapter caddyfile >/dev/null 2>&1; then
  echo '  통과'
else
  echo '  >> 오류 - 적용하지 않는다'
  docker exec caddy caddy validate --config /tmp/t --adapter caddyfile 2>&1 | tail -3 | sed 's/^/  /'
  exit 1
fi

echo ''
echo '=== 3. 적용 ==='
docker exec -i caddy sh -c 'cat > /etc/caddy/Caddyfile' < /root/Caddyfile
docker exec caddy caddy reload --config /etc/caddy/Caddyfile 2>&1 | tail -1
sleep 5

echo ''
echo '=== 4. 확인 ==='
printf '  %-42s %s -> %s\n' 'https://massaviet.com/tuyendung' \
  "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://massaviet.com/tuyendung)" \
  "$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 20 https://massaviet.com/tuyendung)"
echo '  -- 나머지가 멀쩡한지 --'
for u in https://massaviet.com/ https://massaviet.com/vi/ https://massaviet.com/vi/partner.html \
         https://app.massaviet.com/ https://admin.massaviet.com/ \
         https://api.massaviet.com/auth/v1/health https://www.emoiviet.com/; do
  printf '  %-50s %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$u")"
done
echo '  ※ api 는 401, 나머지는 200 이면 정상'
