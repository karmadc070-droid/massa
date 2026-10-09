#!/bin/bash
# 로그인한 테라피스트가 자기 행의 승인·인증을 직접 바꿀 수 있는지 '실제로' 해 본다.
# 전부 하나의 트랜잭션 안에서 하고 마지막에 ROLLBACK 한다. 데이터는 바뀌지 않는다.
#
# 왜 보는가 - "검사는 브라우저에만 있어도 된다" 가 성립하려면
# 브라우저를 거치지 않고는 쓸 수 없어야 한다. 그게 맞는지 확인한다.
set -e

echo '=== 공개 페이지에 anon 키가 들어 있나 ==='
if curl -s --max-time 20 https://app.massaviet.com/config.js | grep -oE 'eyJ[A-Za-z0-9_-]{10}' | head -1 | grep -q eyJ; then
  echo '  >> 들어 있다. 누구나 소스 보기로 가져갈 수 있다.'
else
  echo '  (config.js 에서 못 찾음 - 다른 곳에 있을 수 있다)'
fi

echo ''
echo '=== 로그인 사용자 흉내: 자기 행을 approved + is_verified 로 바꿔 보기 ==='
docker exec -i massa-db psql -U postgres -d postgres <<'SQL'
begin;

-- 실제 로그인 계정이 있는 테라피스트 하나를 고른다
create temp table t as
  select id, profile_id, display_name, is_verified, application_status::text st
    from providers where profile_id is not null limit 1;
select '대상: ' || display_name || ' (지금 is_verified=' || is_verified || ', ' || st || ')' from t;

-- 그 사람으로 로그인한 척한다 (supabase 가 하는 것과 같은 방식)
set local role authenticated;
select set_config('request.jwt.claims',
       json_build_object('sub', (select profile_id::text from t), 'role','authenticated')::text, true);

-- 본인이 자기 행을 직접 고쳐 본다
update providers
   set is_verified = true,
       application_status = 'approved'
 where id = (select id from t);

reset role;
select '바꾼 뒤: is_verified=' || is_verified || ', ' || application_status::text
  from providers where id = (select id from t);

rollback;
SQL

echo ''
echo '=== 롤백됐는지 확인 (원래대로여야 한다) ==='
docker exec -i massa-db psql -U postgres -d postgres < /dev/null -c "
select count(*) filter (where is_verified) 인증켜진사람 from providers;"
