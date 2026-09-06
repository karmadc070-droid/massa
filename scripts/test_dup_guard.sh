#!/bin/sh
# 중복 신청이 막히는지, 정상 신청은 통과하는지. 시험 흔적은 끝에 지운다.
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
\set ON_ERROR_STOP off
select id as demo from auth.users where email='demo@massa.app' \gset
select id as fresh from auth.users where email='trinh1111ttt@gmail.com' \gset

\echo '=== 1. 이미 신청이 있는 계정(demo) 이 또 넣으면 막혀야 한다 ==='
insert into public.providers (profile_id, display_name, kind, application_status)
values (:'demo', '중복시험', 'masseur', 'pending');

\echo '=== 2. 신청이 없는 계정은 통과해야 한다 ==='
insert into public.providers (profile_id, display_name, kind, application_status)
values (:'fresh', '정상시험', 'masseur', 'pending')
returning left(id::text,8) as 만들어짐;

\echo '=== 3. 그 계정이 또 넣으면 이제 막혀야 한다 ==='
insert into public.providers (profile_id, display_name, kind, application_status)
values (:'fresh', '정상시험2', 'masseur', 'pending');

\echo '=== 4. 반려 상태면 다시 신청할 수 있어야 한다 ==='
update public.providers set application_status='rejected'
 where display_name='정상시험';
insert into public.providers (profile_id, display_name, kind, application_status)
values (:'fresh', '재신청시험', 'masseur', 'pending')
returning left(id::text,8) as 재신청됨;

\echo '=== 5. 계정 없는 신청(시드)은 그대로 들어간다 ==='
insert into public.providers (display_name, kind, application_status)
values ('계정없음시험', 'masseur', 'pending')
returning left(id::text,8) as 들어감;

\echo '=== 뒷정리 ==='
delete from public.providers
 where display_name in ('중복시험','정상시험','정상시험2','재신청시험','계정없음시험');
select '남은 마사지사 ' || count(*) || '명' as 확인 from public.providers;
select application_status::text as 상태, count(*) from public.providers group by 1 order by 2 desc;
PSQL
