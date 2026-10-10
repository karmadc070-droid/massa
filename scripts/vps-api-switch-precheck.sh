#!/bin/bash
# api.moahagwon.com → api.massaviet.com 으로 바꾸기 전에, 두 주소가 정말 같은지 센다. 읽기만 한다.
#
# 여기서 하나라도 어긋나면 바꾸는 순간 로그인·사진·예약이 통째로 깨진다.
set -e
OLD=https://api.moahagwon.com
NEW=https://api.massaviet.com
K=$(curl -s https://app.massaviet.com/ | grep -o "eyJhbGciOiAiSFMyNTYi[A-Za-z0-9._-]*" | head -1)
[ -n "$K" ] || { echo '앱에서 익명 키를 못 읽었다 — 중단'; exit 1; }

ok=0; bad=0
cmp2() {   # 설명 경로
  a=$(curl -s --max-time 20 "$OLD$2" -H "apikey: $K" -H "Authorization: Bearer $K")
  b=$(curl -s --max-time 20 "$NEW$2" -H "apikey: $K" -H "Authorization: Bearer $K")
  if [ "$a" = "$b" ] && [ -n "$a" ]; then
    printf '  OK   %-34s (%s 바이트)\n' "$1" "${#a}"; ok=$((ok+1))
  else
    printf '  ★다름★ %-32s 옛 %s / 새 %s 바이트\n' "$1" "${#a}" "${#b}"; bad=$((bad+1))
    echo "        옛: $(echo "$a" | head -c 120)"
    echo "        새: $(echo "$b" | head -c 120)"
  fi
}

echo '=== 1. 같은 응답을 주는가 ==='
cmp2 '인증 설정 (auth/v1/settings)' '/auth/v1/settings'
cmp2 '마사지사 목록 (REST)'        '/rest/v1/providers?select=id,display_name&order=display_name'
cmp2 '서비스 목록 (REST)'          '/rest/v1/services?select=id,name&limit=5'
cmp2 '관리자 함수 거부 (RPC)'      '/rest/v1/rpc/admin_dashboard'

echo ''
echo '=== 2. 인증서가 제대로 붙어 있나 ==='
for h in "$OLD" "$NEW"; do
  printf '  %-26s %s\n' "$h" \
    "$(curl -s -o /dev/null -w 'HTTP %{http_code} / 인증서 %{ssl_verify_result} (0이면 정상)' "$h/auth/v1/settings")"
done

echo ''
echo '=== 3. 사진(스토리지)도 새 주소로 열리나 ==='
P=$(docker exec -i massa-db psql -U postgres -d postgres -t -A < /dev/null \
    -c "select photo_url from providers where photo_url like 'http%' limit 1")
if [ -n "$P" ]; then
  echo "  표본 $P"
  N=$(echo "$P" | sed 's#api\.moahagwon\.com#api.massaviet.com#')
  printf '    옛 주소  %s\n' "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$P")"
  printf '    새 주소  %s\n' "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 "$N")"
else
  echo '  절대주소 사진이 없다'
fi

echo ''
echo '=== 4. DB 에 박혀 있는 옛 주소가 몇 개인가 ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select 'providers.photo_url'  칸, count(*) 개수 from providers where photo_url like '%api.moahagwon.com%'
union all select 'providers.photo_urls', count(*) from providers where array_to_string(photo_urls,',') like '%api.moahagwon.com%'
union all select 'providers.video_url', count(*) from providers where video_url like '%api.moahagwon.com%'
union all select 'provider_kyc 서류',   count(*) from provider_kyc
   where coalesce(id_front_url,'')||coalesce(id_back_url,'')||coalesce(business_license_url,'')||coalesce(cert_url,'')
         like '%api.moahagwon.com%'
order by 2 desc;"

echo ''
echo '=== 5. GoTrue 가 소셜 로그인 복귀를 어디로 보내나 (사람이 콘솔에서 바꿔야 하는 것) ==='
docker inspect massa-auth --format '{{range .Config.Env}}{{println .}}{{end}}' \
  | grep -i "REDIRECT_URI\|SITE_URL"

echo ''
if [ "$bad" -eq 0 ]; then echo "판정 — 두 주소가 같다 ($ok 항목). 바꿔도 된다."
else echo "판정 — ★$bad 항목이 다르다. 원인을 찾기 전에는 바꾸지 말 것.★"; fi
