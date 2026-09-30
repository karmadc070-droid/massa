#!/bin/sh
# 배포된 사이트에 옛 허위 문구가 남아 있는지 본다. 전부 0 이어야 한다.
# 안전 페이지뿐 아니라 FAQ·파트너 페이지에도 같은 문구가 박혀 있었다.
BAD='3단계 검증\|3단계를 모두\|위생 인증 표시\|Three-stage\|Hygiene kit check\|hygiene mark\|Chứng nhận bộ vệ sinh\|dấu vệ sinh trên hồ sơ'
for U in safety.html faq.html partner.html index.html; do
  for P in "" en/ vi/; do
    N=$(curl -s --max-time 25 "https://massaviet.com/$P$U" | grep -c "$BAD")
    printf '  %-22s %s\n' "/$P$U" "$N"
  done
done
echo ''
echo '=== 새 문구가 실제로 들어갔는지 (1 이상이어야 한다) ==='
printf '  ko  %s\n' "$(curl -s https://massaviet.com/safety.html   | grep -c '아직 확인 전')"
printf '  en  %s\n' "$(curl -s https://massaviet.com/en/safety.html | grep -c 'Not verified yet')"
printf '  vi  %s\n' "$(curl -s https://massaviet.com/vi/safety.html | grep -c 'Chưa xác minh')"
