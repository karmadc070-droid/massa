#!/bin/sh
# 운영 콘솔에 오늘 고친 인증 로직이 실제로 올라갔는지 본다.
# 이게 옛 버전이면 승인 버튼을 누르는 순간 인증 마크가 자동으로 붙는다. 반드시 확인할 것.
B=$(curl -s --max-time 25 https://admin.moahagwon.com/)
printf '  크기                      %s bytes\n' "$(printf '%s' "$B" | wc -c)"
printf '  승인=인증 자동부여 (옛 버그) %s  (0 이어야 한다)\n' "$(printf '%s' "$B" | grep -c "is_verified: status === 'approved'")"
printf '  신원 확인 버튼            %s  (1 이상)\n' "$(printf '%s' "$B" | grep -c '신원 확인 주기')"
printf '  자격 확인 버튼            %s  (1 이상)\n' "$(printf '%s' "$B" | grep -c '자격 확인 주기')"
printf '  인증 내리기 버튼          %s  (1 이상)\n' "$(printf '%s' "$B" | grep -c '인증 내리기')"
printf '  서류 없으면 거부하는 검사  %s  (1 이상)\n' "$(printf '%s' "$B" | grep -c '신분증이 올라와 있지 않습니다')"
printf '  옛 위생 인증 버튼         %s  (0 이어야 한다)\n' "$(printf '%s' "$B" | grep -c '위생 인증 부여')"
