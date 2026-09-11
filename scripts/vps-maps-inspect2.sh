#!/bin/sh
# edge-functions 블록의 정확한 모양을 본다. 줄 번호까지 알아야 안전하게 끼워 넣는다.
sed -n '440,495p' /root/massa/docker-compose.yml | cat -n
echo ''
echo '=== 서비스 키 이름 목록 ==='
grep -nE '^  [a-z0-9_-]+:' /root/massa/docker-compose.yml | sed -n '1,40p'
