#!/bin/sh
# 채팅 구조를 보고, 관리자가 Kun 에게 말을 걸려면 어떻게 넣어야 하는지 확인한다.
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
\d public.messages
\echo '--- sender_role 에 실제로 들어가 있는 값 ---'
select sender_role, count(*) from public.messages group by 1;
\echo '--- 지금 있는 대화 (앞 5건) ---'
select left(customer_id::text,8) as 고객, left(provider_id::text,8) as 마사지사,
       sender_role as 보낸쪽, left(body,30) as 내용
  from public.messages order by created_at desc limit 5;
\echo '--- Kun 과 관리자 id ---'
select 'Kun' as 구분, id::text from public.providers where display_name='Kun'
union all
select '관리자', id::text from public.profiles where role='admin' limit 1;
\echo '--- notifications 구조 ---'
\d public.notifications
PSQL
