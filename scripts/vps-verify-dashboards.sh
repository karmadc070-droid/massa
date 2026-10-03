#!/bin/sh
# 두 대시보드가 실제로 서빙되는지 확인한다. 디스크에만 있고 안 나가면 없는 것과 같다.
chk() {
  B=$(curl -s --max-time 25 "$1")
  printf '%s\n' "$2"
  printf '  크기        %s bytes\n' "$(printf '%s' "$B" | wc -c)"
  shift 2
  for k in "$@"; do
    printf '  %-26s %s\n' "$k" "$(printf '%s' "$B" | grep -c -- "$k")"
  done
}

chk https://app.massaviet.com/ '=== 고객 앱 ===' 'id="myDash"' 'loadMyDash' '내 이용 현황' 'dshEsc'
echo ''
chk https://admin.massaviet.com/ '=== 운영 콘솔 ===' 'id="partnerDash"' 'loadPartnerDash' 'mpPartnerDash' '수락 대기'
echo ''
echo '=== Vercel 프록시도 같은 내용을 주는가 (안드로이드 사용자) ==='
A=$(curl -sL --max-time 25 https://app.massaviet.com/      | md5sum | cut -d' ' -f1)
B=$(curl -sL --max-time 25 https://massa-seven.vercel.app/ | md5sum | cut -d' ' -f1)
[ "$A" = "$B" ] && echo '  같다 (정상)' || echo "  다르다  $A / $B"
