#!/bin/bash
# 멀쩡한 Caddyfile 을 찾는다.
# 지금 돌고 있는 설정은 메모리에 살아 있어 서비스는 정상이지만, 파일은 깨져 있다.
# 이 상태로 서버가 재시작되면 Caddy 가 안 뜬다 — 그래서 급하다.
echo '=== 백업 목록과 문법 판정 ==='
for f in $(ls -t /root/Caddyfile /root/Caddyfile.bak.* 2>/dev/null); do
  docker exec -i caddy sh -c 'cat > /tmp/t' < "$f"
  if docker exec caddy caddy validate --config /tmp/t --adapter caddyfile >/dev/null 2>&1; then R=OK; else R=BROKEN; fi
  printf '  %-34s %7s bytes  %s  %s\n' "$(basename "$f")" "$(stat -c %s "$f")" \
    "$(stat -c %y "$f" | cut -c1-16)" "$R"
done

echo ''
echo '=== 깨진 파일의 오류 위치 (가장 최근 것) ==='
docker exec -i caddy sh -c 'cat > /tmp/t' < /root/Caddyfile
docker exec caddy caddy validate --config /tmp/t --adapter caddyfile 2>&1 | tail -2

echo ''
echo '=== 그 언저리 내용 (170~190행) ==='
sed -n '168,192p' /root/Caddyfile | cat -n | sed 's/^/  /'

echo ''
echo '=== 돌고 있는 설정에서 호스트 목록 뽑기 (무엇을 지켜야 하는지) ==='
docker exec caddy sh -c 'wget -qO- http://localhost:2019/config/' 2>/dev/null \
  | grep -oE '"[a-z0-9.-]+\.(com|app)"' | sort -u | head -20
