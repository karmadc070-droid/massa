#!/bin/sh
# 앱 주소가 massa-seven.vercel.app → app.massaviet.com 으로 바뀌었다.
# OAuth 는 redirect_to 가 허용 목록에 없으면 거부된다. 그게 안 옮겨졌는지 본다.
# 판단은 /auth/v1/authorize 의 Location 헤더로 한다 — 요청 자체는 아무 주소나 200 이 난다.
KEY=$(grep -E '^ANON_KEY=' /root/massa/.env | cut -d= -f2-)

echo '=== 1. GoTrue 허용 목록 설정 ==='
grep -E 'SITE_URL|URI_ALLOW_LIST' /root/massa/docker-compose.yml | sed 's/^/  /'
echo '  --- 컨테이너에 실제로 들어간 값 ---'
docker exec massa-auth env | grep -E 'SITE_URL|URI_ALLOW_LIST' | tr ',' '\n' | sed 's/^/  /'

echo ''
echo '=== 2. 각 주소로 구글 로그인이 통과하는가 ==='
for U in \
  "https://app.massaviet.com/" \
  "https://massa-seven.vercel.app/" \
  "https://admin.massaviet.com/" ; do
  L=$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 20 -H "apikey: $KEY" \
      "https://api.moahagwon.com/auth/v1/authorize?provider=google&redirect_to=$U")
  case "$L" in
    *accounts.google.com*) R='통과' ;;
    '')                    R='응답 없음' ;;
    *)                     R="거부 -> $(echo "$L" | cut -c1-90)" ;;
  esac
  printf '  %-34s %s\n' "$U" "$R"
done

echo ''
echo '=== 3. 카카오·애플도 같은지 ==='
for P in kakao apple; do
  L=$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 20 -H "apikey: $KEY" \
      "https://api.moahagwon.com/auth/v1/authorize?provider=$P&redirect_to=https://app.massaviet.com/")
  printf '  %-8s %s\n' "$P" "$(echo "$L" | cut -c1-100)"
done
