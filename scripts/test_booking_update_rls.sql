-- RLS 수정이 실제로 동작하는지 본다. 전부 트랜잭션 안에서 하고 끝에 되돌린다 —
-- 진짜 예약 데이터는 한 줄도 바뀌지 않는다.
--
-- 세 가지를 확인한다.
--   A. owner_id 로 연결된 마사지사가 자기 예약을 완료 처리할 수 있다 (이게 고친 부분)
--   B. profile_id 로 연결된 마사지사도 여전히 된다 (고치다 깨지 않았나)
--   C. 남의 예약은 여전히 못 바꾼다 (너무 열어 버리지 않았나)

begin;

-- 시험이 providers 를 이리저리 바꾸는데, 중복 신청 방지 트리거(Z-19)가 그걸 막는다.
-- 트리거가 제 일을 한 것이지 버그가 아니다. 시험 동안만 끄고, rollback 이면 같이 되돌아간다.
alter table providers disable trigger user;

-- 시험용 사용자 두 명
-- 아무 계정이나 쓰면 안 된다. 이미 마사지사 행이 붙어 있는 계정을 골랐다가
-- '계정 하나당 살아 있는 신청 하나' 유니크 인덱스(Z-19)에 걸렸다.
-- 마사지사 행이 하나도 없는 계정 두 개를 고른다.
create temp table t_ids as
with free as (
  select u.id, row_number() over (order by u.created_at) as rn
  from auth.users u
  where not exists (
    select 1 from providers p where p.owner_id = u.id or p.profile_id = u.id
  )
)
select (select id from free where rn = 1) as me,
       (select id from free where rn = 2) as other;

create temp table t_b as
select b.id as booking_id, b.provider_id
from bookings b where b.provider_id is not null limit 1;

-- 역할을 authenticated 로 바꾼 뒤에도 이 임시 표를 읽어야 한다 (안 주면 permission denied)
grant select on t_ids, t_b to authenticated;

\echo ''
\echo '--- A. owner_id 로 연결된 경우 ---'
update providers set owner_id = (select me from t_ids), profile_id = null
where id = (select provider_id from t_b);

set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', (select me from t_ids), 'role', 'authenticated')::text, true);

with up as (
  update bookings set status = 'completed', completed_at = now()
  where id = (select booking_id from t_b) returning 1
) select count(*) as rows_updated_should_be_1 from up;

reset role;

\echo ''
\echo '--- B. profile_id 로 연결된 경우 ---'
update providers set owner_id = null, profile_id = (select me from t_ids)
where id = (select provider_id from t_b);
update bookings set status = 'confirmed', completed_at = null where id = (select booking_id from t_b);

set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', (select me from t_ids), 'role', 'authenticated')::text, true);

with up as (
  update bookings set status = 'completed', completed_at = now()
  where id = (select booking_id from t_b) returning 1
) select count(*) as rows_updated_should_be_1 from up;

reset role;

\echo ''
\echo '--- C. 남의 예약 (연결 안 된 사람) ---'
update providers set owner_id = null, profile_id = null where id = (select provider_id from t_b);
update bookings set status = 'confirmed', completed_at = null where id = (select booking_id from t_b);

set local role authenticated;
select set_config('request.jwt.claims',
  json_build_object('sub', (select other from t_ids), 'role', 'authenticated')::text, true);

with up as (
  update bookings set status = 'completed', completed_at = now()
  where id = (select booking_id from t_b) returning 1
) select count(*) as rows_updated_should_be_0 from up;

reset role;

rollback;

\echo ''
\echo '--- 되돌렸는지 확인: 완료된 예약이 여전히 0 건이어야 한다 ---'
select count(*) as completed_after_test from bookings where completed_at is not null;
