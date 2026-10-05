-- 마사지사가 '완료 처리' 를 눌러도 아무 일이 안 일어나던 구멍을 막는다.
--
-- 읽기 정책(bookings_provider_read)은 profile_id OR owner_id 둘 다 인정하는데,
-- 쓰기 정책(bookings_admin_update)은 profile_id 만 본다. 그래서 owner_id 로 연결된
-- 마사지사는 자기 예약을 '보기는 하지만 상태를 바꿀 수 없다'. RLS 는 조용히 0행을
-- 업데이트하고 끝나므로 화면에는 오류도 안 뜬다. 지금은 완료가 0건이라 안 터졌을 뿐이다.
--
-- 읽기와 똑같은 조건으로 맞춘다. 관리자는 그대로 전부 허용한다.

drop policy if exists bookings_admin_update on bookings;

create policy bookings_admin_update on bookings
for update
using (
  exists (
    select 1 from profiles
    where profiles.id = auth.uid() and profiles.role = 'admin'::app_role
  )
  or exists (
    select 1 from providers pr
    where pr.id = bookings.provider_id
      and (pr.profile_id = auth.uid() or pr.owner_id = auth.uid())
  )
);

-- 확인용 — using_expr 에 owner_id 가 들어갔는지 눈으로 본다
select polname, pg_get_expr(polqual, polrelid) as using_expr
from pg_policy where polrelid = 'bookings'::regclass and polname = 'bookings_admin_update';
