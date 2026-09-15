#!/bin/sh
# /srv/massa-web 을 누가 갱신하는지 찾는다. 사본이 갈라지는 걸 막으려면 먼저 알아야 한다.
echo '=== /root 의 스크립트 ==='
ls -1 /root/*.sh 2>/dev/null | sed 's/^/  /'

echo ''
echo '=== massa-web 을 건드리는 스크립트 ==='
grep -l 'massa-web' /root/*.sh 2>/dev/null | sed 's/^/  /' || echo '  없음'

echo ''
echo '=== 크론에 걸린 것 ==='
crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$' | sed 's/^/  /'
