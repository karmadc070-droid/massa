#!/bin/sh
# 운영 콘솔 재설정이 끝까지 되는지 확인한다.
# 페이지가 200 이라는 것만으로는 부족하다 — GoTrue 가 그 주소로 돌려보내 줘야 한다.
# 판단은 /auth/v1/verify 의 Location 헤더로 한다. 요청 시점엔 아무 주소나 200 이 난다.
echo '=== 1. 페이지가 있나 ==='
printf '  상태        %s\n' "$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://admin.massaviet.com/reset.html)"
B=$(curl -s --max-time 20 https://admin.massaviet.com/reset.html)
printf '  비밀번호 재설정 화면인가  %s\n' "$(printf '%s' "$B" | grep -c '비밀번호 재설정')"
printf '  경주 버그 고친 판인가     %s\n' "$(printf '%s' "$B" | grep -c '링크를 확인하는 중')"

echo ''
echo '=== 2. GoTrue 가 이 주소로 돌려보내 주는가 ==='
# 판정은 '요청한 주소로 돌아왔는가' 로 한다.
# 처음엔 *app.massaviet.com* 같은 패턴으로 갈랐는데, 차단된 주소도 SITE_URL(app.massaviet.com)
# 로 떨어지기 때문에 evil 주소까지 '허용(정상)' 으로 찍혔다. 스크립트가 거짓말을 했다.
for U in \
  "https://admin.massaviet.com/reset.html" \
  "https://app.massaviet.com/reset.html" \
  "https://evil.example.com/x" ; do
  L=$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 20 \
      "https://api.moahagwon.com/auth/v1/verify?token=dummy&type=recovery&redirect_to=$U")
  HOST=$(printf '%s' "$U" | awk -F/ '{print $3}')
  if printf '%s' "$L" | grep -q "^https://$HOST"; then R='그 주소로 돌아감 (허용)'
  else R="그 주소로 안 감 (차단) -> $(printf '%s' "$L" | awk -F'#' '{print $1}')"; fi
  printf '  %-40s %s\n' "$U" "$R"
done
echo '  ※ evil 주소는 차단돼야 한다. 차단되면 SITE_URL 로 떨어진다.'
