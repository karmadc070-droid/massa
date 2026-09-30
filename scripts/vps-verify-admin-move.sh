#!/bin/sh
# 운영 콘솔 이전이 제대로 됐는지 최종 확인한다.
# 새 주소로 실제 콘솔이 나오는가, 옛 주소는 살아서 넘겨주는가, 로그인 재설정이 깨지지 않았는가.
NEW=https://admin.massaviet.com
OLD=https://admin.moahagwon.com

echo '=== 새 주소 ==='
B=$(curl -s --max-time 25 "$NEW/")
printf '  상태        %s\n' "$(curl -s -o /dev/null -w '%{http_code}' --max-time 25 "$NEW/")"
printf '  크기        %s bytes\n' "$(printf '%s' "$B" | wc -c)"
printf '  운영 콘솔인가 (신원 확인 주기 버튼) %s\n' "$(printf '%s' "$B" | grep -c '신원 확인 주기')"
printf '  인증서      %s\n' "$(curl -s -o /dev/null -w '%{ssl_verify_result}' --max-time 25 "$NEW/" | sed 's/^0$/정상/')"

echo ''
echo '=== 옛 주소 (끊기지 않아야 한다) ==='
printf '  상태        %s -> %s\n' \
  "$(curl -s -o /dev/null -w '%{http_code}' --max-time 25 "$OLD/")" \
  "$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 25 "$OLD/")"
printf '  따라가면    %s\n' "$(curl -sL -o /dev/null -w '%{http_code}' --max-time 30 "$OLD/")"

echo ''
echo '=== 비밀번호 재설정이 새 주소를 받아주는가 ==='
# /auth/v1/verify 의 Location 헤더로 판단한다. 요청 시점에는 아무 주소나 200 이 나오므로 여기서 봐야 한다.
for U in "$NEW/reset.html" "https://evil.example.com/x"; do
  L=$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 20 \
      "https://api.moahagwon.com/auth/v1/verify?token=dummy&type=recovery&redirect_to=$U")
  case "$L" in
    *evil*) R='허용됨 (이러면 안 된다)' ;;
    *admin.massaviet.com*) R='허용됨 (정상)' ;;
    *) R="차단됨 -> $L" ;;
  esac
  printf '  %-40s %s\n' "$U" "$R"
done
