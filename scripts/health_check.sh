#!/bin/sh
# massa 전체 점검. 무엇이 깨져 있는지 눈으로 볼 수 있게 항목마다 판정을 붙인다.
echo '################ 1. 서버·컨테이너 ################'
docker ps --format '{{.Names}}\t{{.Status}}' | sort
echo ''
echo '디스크:'; df -h / | tail -1
echo '메모리:'; free -h | head -2 | tail -1
echo ''

echo '################ 2. 외부에서 열리는가 ################'
for u in https://massaviet.com/ https://www.massaviet.com/ https://massa.moahagwon.com/ \
         https://admin.moahagwon.com/ https://massa-seven.vercel.app/ \
         https://massaviet.com/admin/ https://massa-seven.vercel.app/.well-known/assetlinks.json; do
  printf '%-58s %s\n' "$u" "$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 "$u")"
done
printf '%-58s %s  (401 이 정상)\n' 'https://api.moahagwon.com/auth/v1/settings' \
  "$(curl -s -o /dev/null -w '%{http_code}' --max-time 15 https://api.moahagwon.com/auth/v1/settings)"
echo ''

echo '################ 3. 인증서 만료일 ################'
for h in massaviet.com massa.moahagwon.com admin.moahagwon.com api.moahagwon.com; do
  d=$(echo | openssl s_client -servername "$h" -connect "$h":443 2>/dev/null \
      | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
  printf '%-26s %s\n' "$h" "${d:-확인 실패}"
done
echo ''

echo '################ 4. 배포된 파일이 최신인가 ################'
for f in /srv/massa-web/index.html /srv/massa-admin/index.html; do
  printf '%-32s priceOf=%s  개인가격RPC=%s  %s\n' "$f" \
    "$(grep -c -F 'function priceOf' $f)" \
    "$(grep -c -F 'public_provider_prices' $f)" \
    "$(date -r $f '+%m-%d %H:%M')"
done
echo ''

echo '################ 5. 백업 ################'
ls -1t /root/massa_backup_*.sql* /root/auth_backup_*.sql 2>/dev/null | head -5
echo "백업 개수: $(ls -1 /root/massa_backup_* 2>/dev/null | wc -l)"
crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$'
echo ''

echo '################ 6. DB ################'
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
select '연결 ' || count(*) || '개 · DB 크기 ' || pg_size_pretty(pg_database_size('postgres')) as 상태
  from pg_stat_activity where datname='postgres';

\echo '--- 정책 없이 RLS 만 켜 둔 표 (의도된 잠금) ---'
select c.relname as 표
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
 where n.nspname='public' and c.relrowsecurity
   and not exists (select 1 from pg_policies p where p.schemaname='public' and p.tablename=c.relname)
 order by 1;

\echo '--- ★ RLS 가 아예 꺼진 public 표 (누구나 읽고 쓸 수 있다) ---'
select c.relname as 표
  from pg_class c join pg_namespace n on n.oid=c.relnamespace
 where n.nspname='public' and c.relkind='r' and not c.relrowsecurity
 order by 1;

\echo '--- 예약 금액·수수료 트리거가 살아 있는가 ---'
select tgname as 트리거 from pg_trigger
 where tgrelid='public.bookings'::regclass and not tgisinternal order by 1;

\echo '--- 마사지사·서비스 현황 ---'
select '고객에게 보이는 마사지사 ' || count(*) filter (where is_active and application_status='approved')
    || '명 (그중 계정 없는 시드 ' || count(*) filter (where is_active and application_status='approved'
                                                     and coalesce(profile_id,owner_id) is null) || '명)'
    || ' · 심사 대기 ' || count(*) filter (where application_status='pending') || '명' as 현황
  from public.providers;
select '활성 코스 ' || count(*) filter (where is_active)
    || ' · 내린 코스 ' || count(*) filter (where not is_active) as 코스 from public.services;

\echo '--- 관리자 계정 ---'
select u.email as 계정, pr.role::text as 역할,
       string_agg(i.provider, '·' order by i.provider) as 로그인수단
  from public.profiles pr join auth.users u on u.id=pr.id
  left join auth.identities i on i.user_id=u.id
 where pr.role in ('admin','reviewer') group by 1,2;

\echo '--- 개인 가격 ---'
select count(*) filter (where price_vnd is not null) as 적용중,
       count(*) filter (where pending_vnd is not null) as 승인대기 from public.provider_price;
PSQL
echo ''
echo '################ 7. 메일 발송 ################'
docker logs massa-auth --since 24h 2>&1 | grep -ci 'error' | sed 's/^/auth 오류 로그 줄수: /'
docker logs massa-rest --since 24h 2>&1 | grep -ci 'error' | sed 's/^/rest 오류 로그 줄수: /'
