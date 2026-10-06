#!/bin/bash
# 앞선 스크립트가 /root/Caddyfile 을 깨뜨렸다. 되돌리고 제대로 다시 한다.
#
# 무엇이 잘못됐나 — 블록을 정규식 `massa\.moahagwon\.com\s*\{.*?\n\}\n` 로 잘라냈는데,
# 그 블록 안에 header { ... } 같은 중첩 중괄호가 있었다. 비탐욕 매칭이 '첫 번째' 닫는
# 중괄호에서 멈추는 바람에 블록을 반만 자르고 나머지를 남겼다.
# → 중괄호를 세면서 끝을 찾는 방식으로 바꾼다.
#
# 다행히 Caddy 는 reload 를 거부했고(문법 오류), 옛 설정이 그대로 돌고 있어 장애는 없었다.
set -e

echo '=== 0. 지금 서비스는 살아 있나 (고치기 전 확인) ==='
for u in https://app.massaviet.com/ https://admin.massaviet.com/ https://massaviet.com/; do
  printf '  %-34s %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "$u")"
done

echo ''
echo '=== 1. 백업에서 되돌리기 ==='
# 컨테이너가 들고 있는 '돌아가고 있는' 설정이 가장 믿을 만한 원본이다.
docker exec caddy cat /etc/caddy/Caddyfile > /tmp/running.caddy
BAK=$(ls -t /root/Caddyfile.bak.* 2>/dev/null | head -1)
echo "  최근 백업: $BAK"
# 되돌릴 기준은 '깨지기 전 백업' 이다. 백업이 문법 검사를 통과하는지 먼저 본다.
cp "$BAK" /root/Caddyfile.candidate
docker exec -i caddy sh -c 'cat > /tmp/cand' < /root/Caddyfile.candidate
if docker exec caddy caddy validate --config /tmp/cand --adapter caddyfile >/dev/null 2>&1; then
  echo '  백업 문법 OK — 이걸 기준으로 쓴다'
else
  echo '  ★ 백업도 문법이 깨졌다 — 중단한다'
  exit 1
fi

echo ''
echo '=== 2. 중괄호를 세어 블록을 통째로 교체 ==='
python3 - /root/Caddyfile.candidate <<'PY'
import sys
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
key = 'massa.moahagwon.com'
i = s.find('\n' + key)
if i < 0:
    print('  블록 없음 — 이미 정리됐다'); raise SystemExit(0)
# 여는 중괄호부터 짝이 맞는 닫는 중괄호까지를 센다 (중첩 header{} 때문에 필수)
o = s.index('{', i)
d = 0
for k in range(o, len(s)):
    if s[k] == '{': d += 1
    elif s[k] == '}':
        d -= 1
        if d == 0:
            end = k + 1
            break
new = ('\n# massa-old-retired — 옛 주소. 최근 48시간 실제 접속 0건이라 새 주소로 넘긴다.\n'
       '# (7일 치 65건은 전부 인증서 갱신 로그였다.)\n'
       'massa.moahagwon.com {\n'
       '    redir https://app.massaviet.com{uri} permanent\n'
       '}\n')
s = s[:i] + new + s[end:]
open(p, 'w', encoding='utf-8').write(s)
print('  블록 교체함')
PY

echo ''
echo '=== 3. 문법 검사 (적용 전) ==='
docker exec -i caddy sh -c 'cat > /tmp/cand' < /root/Caddyfile.candidate
if ! docker exec caddy caddy validate --config /tmp/cand --adapter caddyfile 2>&1 | tail -2; then
  echo '  ★ 문법 오류 — 적용하지 않는다'; exit 1
fi
docker exec caddy caddy validate --config /tmp/cand --adapter caddyfile >/dev/null 2>&1 \
  || { echo '  ★ 문법 오류 — 적용하지 않는다'; exit 1; }
echo '  통과'

echo ''
echo '=== 4. 적용 ==='
cp /root/Caddyfile.candidate /root/Caddyfile
docker exec -i caddy sh -c 'cat > /etc/caddy/Caddyfile' < /root/Caddyfile
docker exec caddy caddy reload --config /etc/caddy/Caddyfile 2>&1 | tail -1
sleep 5

echo ''
echo '=== 5. 확인 ==='
for u in https://massa.moahagwon.com/ https://massa.moahagwon.com/privacy.html; do
  printf '  옛 주소 %-32s %s -> %s\n' "$(echo "$u" | sed 's|https://massa.moahagwon.com||')" \
    "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$u")" \
    "$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 20 "$u")"
done
echo '  -- 나머지 --'
for u in https://app.massaviet.com/ https://admin.massaviet.com/ https://massaviet.com/ \
         https://app.massaviet.com/.well-known/assetlinks.json https://massaviet.com/vi/; do
  printf '  %-54s %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$u")"
done
printf '  %-54s %s  (401 정상)\n' 'https://api.moahagwon.com/auth/v1/health' \
  "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://api.moahagwon.com/auth/v1/health)"
printf '  %-54s %s  (1년 캐시여야 함)\n' '앱 아이콘 캐시헤더' \
  "$(curl -s -o /dev/null -D- --max-time 20 https://app.massaviet.com/icon-192.png | grep -i '^cache-control' | tr -d '\r')"
