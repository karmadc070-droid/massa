#!/bin/sh
# 200 이 떴다는 건 페이지가 있다는 뜻일 뿐, 받을 수 있다는 뜻은 아니다.
# 페이지 안에 앱 이름과 설치/가격 정보가 실제로 들어 있는지까지 본다.
UA='Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 Chrome/120 Mobile Safari/537.36'

echo '=== 구글 플레이 (베트남) ==='
P=$(curl -sL --max-time 30 -A "$UA" 'https://play.google.com/store/apps/details?id=app.massa.hanoi&hl=vi&gl=VN')
printf '  크기            %s bytes\n' "$(printf '%s' "$P" | wc -c)"
printf '  <title>         %s\n' "$(printf '%s' "$P" | grep -o '<title>[^<]*' | head -1 | cut -c8-)"
printf '  앱 이름 노출    %s\n' "$(printf '%s' "$P" | grep -ci 'massa')"
printf '  오류 문구       %s\n' "$(printf '%s' "$P" | grep -ciE 'not found|không tìm thấy|찾을 수 없' )"
printf '  버전 표기       %s\n' "$(printf '%s' "$P" | grep -oE '1\.0\.[0-9]+' | sort -u | tr '\n' ' ')"

echo ''
echo '=== 애플 앱스토어 (리다이렉트 따라감) ==='
for L in vn kr; do
  F=$(curl -s -o /dev/null -w '%{redirect_url}' --max-time 25 -A "$UA" "https://apps.apple.com/$L/app/id6804698319")
  C=$(curl -sL --max-time 30 -A "$UA" "https://apps.apple.com/$L/app/id6804698319")
  printf '  [%s] 최종 상태   %s\n' "$L" "$(curl -sL -o /dev/null -w '%{http_code}' --max-time 30 -A "$UA" "https://apps.apple.com/$L/app/id6804698319")"
  printf '       넘어간 곳   %s\n' "$F"
  printf '       <title>     %s\n' "$(printf '%s' "$C" | grep -o '<title>[^<]*' | head -1 | cut -c8-)"
  printf '       버전        %s\n' "$(printf '%s' "$C" | grep -oE '1\.0\.[0-9]+' | sort -u | tr '\n' ' ')"
done
