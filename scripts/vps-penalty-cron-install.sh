#!/bin/sh
# 마사지사 거절 제재를 매일 다시 센다(30일 지난 거절이 빠지면 단계가 내려간다). pg_cron 이 없어 호스트 crontab 을 쓴다.
# 여러 번 돌려도 crontab 줄은 하나만 남는다.
set -e
cat > /root/massa_penalty_refresh.sh <<'EOF'
#!/bin/sh
# 매일 1회: 제재·거절 기록이 있는 마사지사의 단계를 최근 30일 거절 수로 다시 계산(관리자 하한 유지)
echo "$(date -u +%FT%TZ) $(docker exec massa-db psql -U postgres -d postgres -Atc 'select public.refresh_all_provider_penalties()')" >> /root/massa_penalty_refresh.log 2>&1
EOF
chmod +x /root/massa_penalty_refresh.sh
# 하노이 07:17 (UTC 00:17)
( crontab -l 2>/dev/null | grep -v 'massa_penalty_refresh.sh'; echo '17 0 * * * /bin/sh /root/massa_penalty_refresh.sh' ) | crontab -
crontab -l | grep massa_penalty_refresh
/bin/sh /root/massa_penalty_refresh.sh
tail -1 /root/massa_penalty_refresh.log
