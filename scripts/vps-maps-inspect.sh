#!/bin/sh
# 지도 키를 넣기 전에, 엣지 함수가 어디에 어떻게 붙어 있는지 먼저 본다. 추측하지 않는다.
echo '=== 1. maps.key 있는가 ==='
[ -f /root/maps.key ] && echo "있음 (길이 $(tr -d '\n' < /root/maps.key | wc -c))" || echo '없음'

echo ''
echo '=== 2. 엣지 함수 폴더 ==='
ls -1 /root/massa/volumes/functions/ 2>/dev/null || echo '(functions 폴더 없음)'

echo ''
echo '=== 3. places-search 배포됐는가 ==='
ls -la /root/massa/volumes/functions/places-search/ 2>/dev/null || echo '(없음 — 배포 필요)'

echo ''
echo '=== 4. edge-functions 컨테이너 환경 설정 ==='
grep -n 'functions' -A 25 /root/massa/docker-compose.yml | grep -n -iE 'environment|_KEY|SECRET|URL|image:|container_name' | head -30

echo ''
echo '=== 5. .env 에 이미 지도 키가 있는가 (이름만) ==='
grep -oE '^[A-Z_]+' /root/massa/.env 2>/dev/null | grep -iE 'GOOGLE|MAP|PLACE' || echo '(없음)'
