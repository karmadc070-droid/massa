#!/bin/sh
# Edge Function 과 .env 의 실제 경로를 확인한다. 키 값은 출력하지 않는다.
echo '=== massa 스택 위치 ==='
ls -d /root/massa 2>/dev/null || echo '/root/massa 없음'
find /root -maxdepth 3 -name 'docker-compose.yml' 2>/dev/null | head

echo '=== .env 후보 (키 이름만) ==='
for f in /root/massa/docker/.env /root/massa/.env; do
  [ -f "$f" ] && { echo "--- $f ---"; cut -d= -f1 "$f" | sort; }
done

echo '=== functions 폴더 ==='
find /root -maxdepth 5 -type d -name functions 2>/dev/null | head
ls -la /root/massa/volumes/functions 2>/dev/null || echo 'volumes/functions 없음'

echo '=== edge-functions 컨테이너 마운트 ==='
docker inspect massa-edge-functions --format '{{range .Mounts}}{{.Source}} -> {{.Destination}}{{"\n"}}{{end}}' 2>/dev/null
