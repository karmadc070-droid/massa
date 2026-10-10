#!/bin/bash
# massaviet.com/admin 앞에 구글 로그인 문지기를 세운다 (1단계 — 문지기만 띄운다).
#
# 지금 상태 — 데이터는 DB 가 막고 있어서 남이 가져갈 수 없다.
#             하지만 '화면' 은 누구나 연다. 로그인 창까지는 보인다.
#             문지기를 세우면 로그인 창조차 안 보인다.
#
# 왜 두 단계로 나누나 — Caddy 를 먼저 연결하면, 구글에 복귀 주소가 등록되기 전까지
#   사장님도 못 들어간다. 문지기를 먼저 띄워 두고 구글 등록을 마친 뒤에 연결한다.
#
# 구글 클라이언트는 emoi 가 쓰던 것을 같이 쓴다. 새로 만들면 사람이 할 일이 늘기만 한다.
# 사람이 할 일은 '승인된 리디렉션 URI' 에 한 줄 추가뿐이다.
set -e

DIR=/root/massa-oauth2
PORT=4181          # emoi 가 4180 을 쓰고 있다
mkdir -p "$DIR"

# 들어올 수 있는 사람. **구글 계정으로 등록된 주소**여야 한다.
# icloud 주소도 구글 계정을 만들어 뒀다면 통과한다. 안 만들었으면 못 들어온다.
# reviewer@massa.app 는 구글 계정이 아니라서 이 문으로는 못 들어온다 (DB 로그인은 그대로 된다).
cat > "$DIR/emails.txt" <<'EOF'
karmadc070@gmail.com
moahagwon@gmail.com
karmadc77@icloud.com
EOF
# 644 여야 한다. oauth2-proxy 는 컨테이너 안에서 root 가 아닌 사용자로 돈다.
# 600 으로 두면 "permission denied" 로 재시작만 반복한다 (실제로 한 번 그랬다).
chmod 644 "$DIR/emails.txt"

# 비밀값은 emoi 컨테이너에서 그대로 가져온다. 화면에 찍지 않는다.
CID=$(docker inspect emoi-oauth2-proxy --format '{{range .Config.Env}}{{println .}}{{end}}' \
      | grep '^OAUTH2_PROXY_CLIENT_ID=' | cut -d= -f2-)
CSEC=$(docker inspect emoi-oauth2-proxy --format '{{range .Config.Env}}{{println .}}{{end}}' \
      | grep '^OAUTH2_PROXY_CLIENT_SECRET=' | cut -d= -f2-)
[ -n "$CID" ] && [ -n "$CSEC" ] || { echo 'emoi 에서 구글 키를 못 읽었다 — 중단'; exit 1; }
# 쿠키 서명용. massa 전용으로 새로 뽑는다 (emoi 와 섞지 않는다).
CSECRET=$(head -c 32 /dev/urandom | base64 | tr '+/' '-_' | tr -d '=')

docker rm -f massa-oauth2-proxy 2>/dev/null || true
docker run -d --name massa-oauth2-proxy --restart unless-stopped \
  -p 127.0.0.1:$PORT:$PORT \
  -v "$DIR/emails.txt":/etc/oauth2-proxy/emails.txt:ro \
  -e OAUTH2_PROXY_CLIENT_ID="$CID" \
  -e OAUTH2_PROXY_CLIENT_SECRET="$CSEC" \
  -e OAUTH2_PROXY_COOKIE_SECRET="$CSECRET" \
  quay.io/oauth2-proxy/oauth2-proxy:v7.13.0 \
    --provider=google \
    --http-address=0.0.0.0:$PORT \
    --reverse-proxy=true \
    --redirect-url=https://massaviet.com/oauth2/callback \
    --authenticated-emails-file=/etc/oauth2-proxy/emails.txt \
    --upstream=static://202 \
    --set-xauthrequest=true \
    --skip-provider-button=true \
    --cookie-secure=true \
    --cookie-domain=massaviet.com \
    --whitelist-domain=massaviet.com \
    --cookie-expire=168h \
    --cookie-refresh=1h

sleep 4
echo '=== 문지기 상태 ==='
docker ps --format '{{.Names}}\t{{.Status}}\t{{.Ports}}' | grep massa-oauth2-proxy
echo ''
echo '=== 살아 있나 (401 이 정상 — 아직 로그인 안 했으니까) ==='
curl -s -o /dev/null -w '  /oauth2/auth  HTTP %{http_code}\n' "http://127.0.0.1:$PORT/oauth2/auth"
echo ''
echo '=== 최근 로그 ==='
docker logs massa-oauth2-proxy 2>&1 | tail -6
echo ''
echo '=== 다음에 사람이 할 일 ==='
echo '  구글 클라우드 콘솔 → 사용자 인증 정보 → OAuth 2.0 클라이언트 ID'
echo "  $CID"
echo '  승인된 리디렉션 URI 에 아래 한 줄 추가'
echo '      https://massaviet.com/oauth2/callback'
echo '  (emoi 것은 지우지 말 것. 추가만 한다)'
echo ''
echo '  그 뒤 scripts/vps-admin-oauth2-connect.sh 를 돌리면 문이 잠긴다.'
