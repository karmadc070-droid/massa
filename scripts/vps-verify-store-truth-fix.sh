#!/bin/sh
# 매장 카드에서 지어낸 숫자가 정말 사라졌는지 서빙되는 쪽에서 확인한다.
# 디스크만 보면 안 된다 — 배포가 빠지면 고친 게 아니다.
B=$(curl -s --max-time 25 https://app.massaviet.com/)
printf '크기 %s bytes\n\n' "$(printf '%s' "$B" | wc -c)"

echo '=== 사라져야 하는 것 (전부 0) ==='
for k in \
  "s.rate.toFixed" \
  "class=\"spct\"" \
  "class=\"sbadge\"" \
  "hygiene_certified ?" \
  "14~17시 예약 시 20% 할인" \
  "60분 릴랙스 코스 첫 고객 체험가" \
  "지역별 인기·가성비 매장을 모아" \
  "위생 교육을 마친" ; do
  printf '  %-34s %s\n' "$k" "$(printf '%s' "$B" | grep -c -- "$k")"
done

echo ''
echo '=== 남아 있어야 하는 것 (1 이상) ==='
for k in \
  "아직 제휴한 매장이 아니라서" \
  "신분증과 자격 서류 확인이 끝난" \
  "아직 후기 없음" \
  "신규 도착" ; do
  printf '  %-34s %s\n' "$k" "$(printf '%s' "$B" | grep -c -- "$k")"
done

echo ''
echo '=== 정상 배지가 살아 있나 (지우다가 같이 날린 적 있다) ==='
printf '  동적 ✓ 신원 확인   %s\n' "$(printf '%s' "$B" | grep -c 'is_verified ?')"
printf '  동적 ★ 자격 확인   %s\n' "$(printf '%s' "$B" | grep -c 'credential_verified ?')"

echo ''
echo '=== 안드로이드(Vercel 프록시)도 같은 내용인가 ==='
A=$(printf '%s' "$B" | md5sum | cut -d' ' -f1)
V=$(curl -sL --max-time 25 https://massa-seven.vercel.app/ | md5sum | cut -d' ' -f1)
[ "$A" = "$V" ] && echo '  같다 (정상)' || echo "  다르다 $A / $V"
