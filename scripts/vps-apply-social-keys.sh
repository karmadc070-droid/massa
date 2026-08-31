#!/bin/sh
# 발급받은 소셜 로그인 키를 .env 에 넣고 auth 를 다시 올린다.
#
# 사전 준비: 아래 형식으로 /root/social.keys 를 만들어 둘 것 (noVNC 클립보드나 편집기로).
#   GOOGLE_CLIENT_ID=...
#   GOOGLE_SECRET=...
#   KAKAO_CLIENT_ID=...
#   KAKAO_SECRET=...
#   APPLE_CLIENT_ID=...
#   APPLE_SECRET=...
# 일부만 적어도 된다. 적힌 것만 켜진다.
set -e

ENVF=/root/massa/.env
KEYS=/root/social.keys

[ -f "$KEYS" ] || { echo "$KEYS 가 없다. 키 파일을 먼저 만들 것"; exit 1; }
cp "$ENVF" "$ENVF.bak.$(date +%s)"

set_kv() {
  key="$1"; val="$2"
  [ -z "$val" ] && return 0
  if grep -q "^$key=" "$ENVF"; then
    python3 - "$ENVF" "$key" "$val" <<'PY'
import sys
p, k, v = sys.argv[1], sys.argv[2], sys.argv[3]
out = []
for line in open(p, encoding='utf-8'):
    out.append(k + '=' + v + '\n' if line.startswith(k + '=') else line)
open(p, 'w', encoding='utf-8').writelines(out)
PY
  else
    echo "$key=$val" >> "$ENVF"
  fi
}

# 키 파일을 읽어 반영하고, 값이 있는 provider 는 ENABLED=true 로 켠다
for prov in GOOGLE KAKAO APPLE; do
  cid=$(grep "^${prov}_CLIENT_ID=" "$KEYS" 2>/dev/null | head -1 | cut -d= -f2- | tr -d ' \r')
  sec=$(grep "^${prov}_SECRET=" "$KEYS" 2>/dev/null | head -1 | cut -d= -f2- | tr -d ' \r')
  if [ -n "$cid" ] && [ -n "$sec" ]; then
    set_kv "${prov}_CLIENT_ID" "$cid"
    set_kv "${prov}_SECRET" "$sec"
    set_kv "${prov}_ENABLED" "true"
    echo "$prov 켬"
  else
    echo "$prov 건너뜀 (키 없음)"
  fi
done

echo
echo "=== 반영 결과 (값은 가림) ==="
grep -E "^(GOOGLE|KAKAO|APPLE)_" "$ENVF" | sed 's/\(CLIENT_ID\|SECRET\)=.*/\1=***입력됨***/'

echo
echo "=== auth 재기동 ==="
cd /root/massa
docker compose up -d auth
sleep 10

echo
echo "=== settings 확인 ==="
curl -s https://api.moahagwon.com/auth/v1/settings \
  -H "apikey: $(grep '^ANON_KEY=' "$ENVF" | cut -d= -f2-)" \
  | python3 -c "import sys,json; e=json.load(sys.stdin)['external']; print('google:',e['google'],' kakao:',e['kakao'],' apple:',e['apple'])"

echo
echo "=== 키 파일 삭제 ==="
shred -u "$KEYS" 2>/dev/null || rm -f "$KEYS"
echo "삭제함"
echo "=== SOCIAL KEYS DONE ==="
