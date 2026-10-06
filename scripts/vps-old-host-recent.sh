#!/bin/sh
# 옛 주소에 '최근' 접속이 있는지만 본다. 7일 전 기록은 업데이트 전 것일 수 있어
# 닫아도 되는지 판단할 근거가 못 된다. 24시간·48시간으로 좁힌다.
C=$(docker ps --format '{{.Names}}' | grep -i caddy | head -1)

for H in massa-seven.vercel.app massa.moahagwon.com; do
  echo "=== $H ==="
  for W in 24h 48h 168h; do
    N=$(docker logs --since "$W" "$C" 2>&1 | grep -c "$H")
    printf '  최근 %-5s %s건\n' "$W" "$N"
  done
  echo '  -- 최근 48시간 요청 (있으면) --'
  docker logs --since 48h "$C" 2>&1 | grep "$H" | tail -3 | cut -c1-200 | sed 's/^/    /'
  echo ''
done

echo '=== 참고: app.massaviet.com (지금 쓰는 주소) ==='
printf '  최근 24h %s건\n' "$(docker logs --since 24h "$C" 2>&1 | grep -c 'app.massaviet.com')"
