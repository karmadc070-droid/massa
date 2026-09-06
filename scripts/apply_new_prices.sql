-- 2026-09-06 가격 개편. GLOW 하노이 시세(60분 500,000 · 90분 600,000 · 120분 700,000)에 맞춘다.
-- 예약이 services.id 를 참조하므로 빠진 항목은 지우지 않고 비활성으로 내린다.

begin;

-- ── 1. 마사지 전 항목을 시간별 단일 가격으로 ──────────────────
update public.services set price_vnd = 500000 where category = 'massage' and duration_min = 60;
update public.services set price_vnd = 600000 where category = 'massage' and duration_min = 90;
update public.services set price_vnd = 700000 where category = 'massage' and duration_min = 120;

-- ── 2. 홈뷰티·케어 — 값이 바뀌는 것은 없다. 확인만 하고 넘어간다 ──
-- (가슴 350,000 / 각질 350,000 / 겨드랑이 250,000 / 귀청소 200,000 / 네일 400,000 /
--  네일연장 550,000 / 다리전체 550,000 / 복부 300,000 / 비키니 500,000 /
--  젤매니큐어 380,000 / 젤페디큐어 400,000 / 팔전체 400,000 / 한국식스크럽 500,000)

-- ── 3. '왁싱 60분' 은 '풀 왁싱 90분' 이 대신한다. 지우지 않고 내린다 ──
update public.services set is_active = false
 where category = 'therapist_care' and name = '왁싱 60분';

-- ── 4. 신규: 풀 왁싱 90분 ────────────────────────────────────
insert into public.services (category, massage_type, name, duration_min, price_vnd, is_active)
select 'therapist_care', null, '풀 왁싱 90분(겨드랑이,팔,다리,복부,비키니)', 90, 1200000, true
 where not exists (
   select 1 from public.services
    where name = '풀 왁싱 90분(겨드랑이,팔,다리,복부,비키니)');

commit;

-- ── 확인 ─────────────────────────────────────────────────────
select '활성 ' || count(*) filter (where is_active)
    || ' · 비활성 ' || count(*) filter (where not is_active) as 항목수
  from public.services;

select duration_min as 시간, price_vnd as 가격, count(*) as 개수
  from public.services where category = 'massage' and is_active
 group by 1, 2 order by 1;

select name as 홈뷰티, duration_min as 분, price_vnd as 가격,
       case when is_active then '판매' else '내림' end as 상태
  from public.services where category = 'therapist_care' order by is_active desc, name;
