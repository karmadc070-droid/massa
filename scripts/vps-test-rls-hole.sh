#!/bin/bash
# 로그인한 테라피스트가 자기 행의 승인·인증을 직접 바꿀 수 있는지 '실제로' 해 본다.
# 전부 하나의 트랜잭션 안에서 하고 마지막에 ROLLBACK 한다. 데이터는 바뀌지 않는다.
set -e
PSQL() { docker exec -i massa-db psql -U postgres -d postgres "$@"; }

# 대상 한 명을 먼저 뽑아 변수에 담는다 (임시테이블은 role 을 바꾸면 못 읽는다)
read -r PID PROF NAME <<< "$(PSQL -t -A -F' ' < /dev/null -c \
  "select id, profile_id, replace(display_name,' ','_') from providers where profile_id is not null limit 1;")"
echo "대상: $NAME"
echo "  provider id = $PID"
echo "  로그인 계정 = $PROF"

echo ''
echo '=== 그 사람으로 로그인한 척하고 자기 행을 고쳐 본다 ==='
PSQL <<SQL
begin;
set local role authenticated;
select set_config('request.jwt.claims',
       json_build_object('sub','$PROF','role','authenticated')::text, true);

-- 1) 인증 마크를 스스로 켤 수 있나
update providers set is_verified = true where id = '$PID';
select '  is_verified 직접 켜기 -> 바뀐 행 ' || count(*) from providers
 where id = '$PID' and is_verified;

-- 2) 승인 상태를 스스로 바꿀 수 있나
update providers set application_status = 'approved', is_active = true where id = '$PID';
select '  application_status 직접 바꾸기 -> ' || application_status::text
  from providers where id = '$PID';

-- 3) 남의 행도 되나
update providers set is_verified = true where id <> '$PID';
select '  남의 행까지 켜진 수 -> ' || count(*) from providers
 where id <> '$PID' and is_verified;

reset role;
rollback;
SQL

echo ''
echo '=== 롤백 확인 (0 이어야 정상) ==='
PSQL -t -A < /dev/null -c "select '인증 켜진 사람: ' || count(*) from providers where is_verified;"
