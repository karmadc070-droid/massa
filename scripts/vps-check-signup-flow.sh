#!/bin/bash
# 가입 흐름이 실제로 어떻게 설정돼 있는지 본다. 읽기만 한다.
# 보려는 것 - 고객 가입이 정말 '자동' 인가(메일 확인 없이 바로 쓰나).
set -e

echo '=== 1. auth 컨테이너 가입 관련 설정 ==='
docker exec massa-auth env 2>/dev/null \
  | grep -iE 'AUTOCONFIRM|MAILER_AUTOCONFIRM|DISABLE_SIGNUP|EXTERNAL_EMAIL_ENABLED|SECURITY_' \
  | sort | sed 's/^/  /'

echo ''
echo '=== 2. 실제 가입된 계정들의 메일 확인 상태 ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select
  count(*) total,
  count(*) filter (where email_confirmed_at is not null) 확인됨,
  count(*) filter (where email_confirmed_at is null)     미확인
from auth.users;"

echo '=== 3. 가입 직후 바로 확인됐나 (가입시각과 확인시각 차이) ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select to_char(created_at,'MM-DD HH24:MI') 가입,
       coalesce(to_char(email_confirmed_at,'MM-DD HH24:MI'),'(미확인)') 확인,
       round(extract(epoch from (email_confirmed_at - created_at)))::text || 's' 걸린시간
  from auth.users order by created_at desc limit 8;"

echo '=== 4. providers.application_status 분포 (테라피스트 승인 상태) ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select application_status, count(*) from providers group by 1 order by 2 desc;"
