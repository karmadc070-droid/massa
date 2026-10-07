#!/bin/bash
# api.massaviet.com 을 기존 api.moahagwon.com 과 '같이' 받도록 Caddy 에 추가한다.
#
# 왜 교체가 아니라 추가인가 —
# 이미 깔린 iOS 1.0.8/1.0.9 는 api.moahagwon.com 을 코드에 박은 채로 돌아간다.
# 그 주소를 끊으면 그 사용자들은 전부 로그인이 깨진다. 그래서 두 주소를 한동안 같이 연다.
# 앱의 기본값 전환은 다음 빌드 때 따로 한다(DB 안의 절대 URL 74개도 그때 같이 고쳐야 한다).
#
# 절차는 지난번 사고 이후 정해둔 그대로 — 중괄호 세기 없이 '끝에 블록 추가' 뿐이고,
# validate 를 통과해야만 적용하고, 적용은 컨테이너 안쪽 파일에 직접 써 넣는다.
set -e

echo '=== 0. 지금 상태 ==='
printf '  이미 들어있나: %s\n' "$(grep -c 'api.massaviet.com' /root/Caddyfile)"
printf '  DNS: %s\n' "$(getent hosts api.massaviet.com | awk '{print $1}' | tr '\n' ' ')"
printf '  기존 api 블록: %s\n' "$(grep -c 'api.moahagwon.com' /root/Caddyfile)"

if [ "$(grep -c 'api.massaviet.com' /root/Caddyfile)" != "0" ]; then
  echo '  이미 있다 — 중단한다'
  exit 0
fi

echo ''
echo '=== 1. 기존 api 블록 내용 (그대로 베낀다) ==='
python3 - /root/Caddyfile <<'PY'
import sys
s = open(sys.argv[1], encoding='utf-8').read()
i = s.find('api.moahagwon.com')
o = s.index('{', i); d = 0
for k in range(o, len(s)):
    if s[k] == '{': d += 1
    elif s[k] == '}':
        d -= 1
        if d == 0:
            end = k + 1; break
print('\n'.join('  ' + l for l in s[i:end].splitlines()))
PY

echo ''
echo '=== 2. 끝에 새 블록 추가 ==='
cp /root/Caddyfile "/root/Caddyfile.bak.$(date +%s)"
cat >> /root/Caddyfile <<'EOF'

# api.massaviet.com - api.moahagwon.com 과 같은 곳을 본다.
# 앱의 기본 주소를 옮기는 중이라 한동안 둘 다 열어둔다.
api.massaviet.com {
    reverse_proxy localhost:8002
}
EOF
echo '  추가함'

echo ''
echo '=== 3. 문법 검사 (적용 전) ==='
docker exec -i caddy sh -c 'cat > /tmp/t' < /root/Caddyfile
if docker exec caddy caddy validate --config /tmp/t --adapter caddyfile >/dev/null 2>&1; then
  echo '  통과'
else
  echo '  >> 오류 - 적용하지 않는다'
  docker exec caddy caddy validate --config /tmp/t --adapter caddyfile 2>&1 | tail -3 | sed 's/^/  /'
  exit 1
fi

echo ''
echo '=== 4. 적용 ==='
docker exec -i caddy sh -c 'cat > /etc/caddy/Caddyfile' < /root/Caddyfile
docker exec caddy caddy reload --config /etc/caddy/Caddyfile 2>&1 | tail -1
echo '  인증서 발급 대기 20초'
sleep 20

echo ''
echo '=== 5. 확인 - 새 주소 ==='
printf '  %-48s %s  (401 정상)\n' 'https://api.massaviet.com/auth/v1/health' \
  "$(curl -s -o /dev/null -w '%{http_code}' --max-time 25 https://api.massaviet.com/auth/v1/health)"

echo ''
echo '=== 6. 확인 - 기존 것들이 멀쩡한지 ==='
printf '  %-48s %s  (401 정상)\n' 'https://api.moahagwon.com/auth/v1/health' \
  "$(curl -s -o /dev/null -w '%{http_code}' --max-time 25 https://api.moahagwon.com/auth/v1/health)"
for u in https://app.massaviet.com/ https://admin.massaviet.com/ https://massaviet.com/ \
         https://massaviet.com/vi/ https://www.emoiviet.com/; do
  printf '  %-48s %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 25 "$u")"
done
printf '  %-48s %s -> %s\n' 'https://massa.moahagwon.com/' \
  "$(curl -s -o /dev/null -w '%{http_code}' --max-time 25 https://massa.moahagwon.com/)" \
  "$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 25 https://massa.moahagwon.com/)"
