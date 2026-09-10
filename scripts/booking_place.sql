-- 예약에 방문 좌표를 남긴다. 지금은 호텔 이름만 있어서 마사지사가 주소를 직접 찾아야 한다.
--
-- 좌표는 손님 화면이 보내는 값이지만 돈이 걸린 값이 아니다(요금은 코스로 정해진다).
-- 다만 말도 안 되는 값이 들어오면 길찾기가 엉뚱한 곳을 가리키므로 범위만 확인한다.

alter table public.bookings add column if not exists lat      double precision;
alter table public.bookings add column if not exists lng      double precision;
alter table public.bookings add column if not exists place_id text;

-- 지구 밖 좌표를 막는다. 값이 없는 것(null)은 허용한다 — 주소를 직접 적는 손님도 있다.
do $$ begin
  alter table public.bookings add constraint bookings_latlng_range
    check ((lat is null or lat between -90 and 90) and (lng is null or lng between -180 and 180));
exception when duplicate_object then null; end $$;

-- ── 확인 ─────────────────────────────────────────────────────
select column_name as 칸, data_type as 자료형
  from information_schema.columns
 where table_schema='public' and table_name='bookings'
   and column_name in ('lat','lng','place_id','address','hotel_name')
 order by column_name;

select case when exists (select 1 from pg_constraint where conname = 'bookings_latlng_range')
            then '좌표 범위 검사 걸림' else '★ 없음' end as 확인;
