#!/bin/sh
# 운영 콘솔을 admin.moahagwon.com → admin.massaviet.com 으로 옮긴다.
#
# 왜: admin.moahagwon.com 은 학원 도메인이다. massa 운영 화면이 남의 집 주소에 얹혀 있었다.
#
# 원칙 — **옛 주소를 끊지 않는다.** 새 주소를 옆에 세우고, 옛 주소는 새 주소로 넘겨준다.
#        지금 사장님이 옛 주소에서 비밀번호를 재설정하는 중일 수 있다. 끊으면 그게 깨진다.
#
# 전제 — Cloudflare 에 A 레코드가 있어야 한다. admin.massaviet.com → 141.164.46.88, **DNS only(회색 구름)**.
#        주황 구름이면 Caddy 가 HTTP-01 인증서를 못 받는다. 이건 예전에 한 번 겪은 함정이다.
set -e
NEW=admin.massaviet.com
OLD=admin.moahagwon.com
IP=141.164.46.88

echo '=== 0. 전제 확인 — DNS 가 우리 서버를 가리키는가 ==='
GOT=$(dig +short A "$NEW" | tr '\n' ' ')
printf '  %s A = %s\n' "$NEW" "$GOT"
case " $GOT " in
  *" $IP "*) echo '  좋다. 계속한다.' ;;
  *) echo "  ✗ $NEW 이 $IP 을 가리키지 않는다. Cloudflare 에 A 레코드를 먼저 넣어라. 중단한다."; exit 1 ;;
esac

echo ''
echo '=== 1. 백업 ==='
cp /root/Caddyfile "/root/Caddyfile.bak.$(date +%s)"
cp /root/massa/.env "/root/massa/.env.bak.$(date +%s)"
echo '  Caddyfile · .env 백업함'

echo ''
echo '=== 2. Caddy 에 새 주소 추가 ==='
if grep -q "^$NEW {" /root/Caddyfile; then
  echo '  이미 있다 — 건너뜀'
else
  cat >> /root/Caddyfile <<EOF

$NEW {
    root * /srv/massa-admin
    file_server
    encode gzip
    header {
        X-Frame-Options "DENY"
        X-Content-Type-Options "nosniff"
        Referrer-Policy "strict-origin-when-cross-origin"
    }
}
EOF
  echo "  $NEW 추가함"
fi

echo ''
echo '=== 3. 옛 주소는 끊지 않고 새 주소로 넘긴다 ==='
# root/file_server 를 지우고 redir 로 바꾼다. 북마크와 예전 메일 링크가 살아 있게 하기 위해서다.
python3 - "$OLD" "$NEW" <<'PY'
import re, sys
old, new = sys.argv[1], sys.argv[2]
p = '/root/Caddyfile'
s = open(p, encoding='utf-8').read()
m = re.search(r'(?m)^' + re.escape(old) + r' \{.*?^\}\n', s, re.S)
if not m:
    print('  옛 블록을 못 찾았다 — 손대지 않는다'); raise SystemExit
if 'redir' in m.group(0):
    print('  이미 리다이렉트로 바뀌어 있다 — 건너뜀'); raise SystemExit
block = old + ' {\n    redir https://' + new + '{uri} permanent\n}\n'
open(p, 'w', encoding='utf-8').write(s[:m.start()] + block + s[m.end():])
print('  ' + old + ' → ' + new + ' 영구 리다이렉트로 바꿈')
PY

echo ''
echo '=== 4. GoTrue 허용목록에 새 주소 추가 (/* 와 /** 둘 다) ==='
# 하나만 넣으면 지금은 되는 것처럼 보이다가 SITE_URL 이 바뀌는 날 조용히 깨진다. 예전에 겪었다.
python3 - "$NEW" <<'PY'
import re, sys
new = sys.argv[1]
p = '/root/massa/.env'
s = open(p, encoding='utf-8').read()
m = re.search(r'(?m)^ADDITIONAL_REDIRECT_URLS=(.*)$', s)
cur = [x for x in m.group(1).split(',') if x]
add = [u for u in ('https://%s/*' % new, 'https://%s/**' % new) if u not in cur]
if not add:
    print('  이미 들어 있다 — 건너뜀'); raise SystemExit
out = ','.join(cur + add)
open(p, 'w', encoding='utf-8').write(s[:m.start(1)] + out + s[m.end(1):])
print('  추가: ' + ', '.join(add))
PY

echo ''
echo '=== 5. 적용 ==='
docker exec caddy caddy reload --config /etc/caddy/Caddyfile 2>/dev/null \
  || docker restart caddy >/dev/null
cd /root/massa && docker compose up -d auth >/dev/null
echo '  Caddy reload · auth 재시작 완료'

echo ''
echo '=== 6. 검증 ==='
sleep 20
printf '  %-34s %s (200 이어야 한다)\n' "https://$NEW/" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 30 "https://$NEW/")"
printf '  %-34s %s (301 이어야 한다) -> %s\n' "https://$OLD/" \
  "$(curl -s -o /dev/null -w '%{http_code}' --max-time 30 "https://$OLD/")" \
  "$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 30 "https://$OLD/")"
echo '  허용목록:'
grep -E '^ADDITIONAL_REDIRECT_URLS=' /root/massa/.env | sed 's/^ADDITIONAL_REDIRECT_URLS=//' | tr ',' '\n' | sed 's/^/    /'
