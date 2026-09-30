#!/bin/sh
# 사장님이 말씀한 새 도메인 massaveit.com 이 실제로 존재하는지 확인한다.
# 기존 도메인은 massaviet.com (vi-et) 이고 새 것은 massaveit.com (ve-it) 이다. 철자가 다르다.
# 오타인지 진짜 새 도메인인지 먼저 가린다. 틀린 주소로 옮기면 서비스가 통째로 죽는다.
for D in massaveit.com www.massaveit.com massaviet.com www.massaviet.com; do
  echo "=== $D ==="
  printf '  A 레코드 : '; (dig +short A "$D" | tr '\n' ' ' || true); echo ''
  printf '  NS       : '; (dig +short NS "$D" | tr '\n' ' ' || true); echo ''
  printf '  HTTPS    : '; curl -s -o /dev/null -w '%{http_code} (%{redirect_url})' --max-time 15 "https://$D/" || true; echo ''
done
