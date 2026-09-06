-- 종류 값이 커밋된 뒤 실행한다 (enum 은 같은 트랜잭션에서 바로 못 쓴다).
-- 이름만 다른 중복은 하나만 남기고 내린다. 예약이 참조하므로 지우지 않는다.

begin;

-- ── 1. 남길 것에 종류를 붙인다 ────────────────────────────────
update public.services set massage_type = 'hot_stone'     where name like '핫 스톤마사지%';
update public.services set massage_type = 'foot'          where name like '다리 마사지%';
update public.services set massage_type = 'head'          where name like '머리 마사지%';
update public.services set massage_type = 'back'          where name like '등 테라피%';
update public.services set massage_type = 'neck_shoulder' where name like '목·어깨 테라피%';
update public.services set massage_type = 'sports'        where name like '스포츠 테라피%';
update public.services set massage_type = 'cupping'       where name like '오일 마사지 + 부항 요법%';
update public.services set massage_type = 'no_oil'        where name like '오일 없는 마사지%';

-- ── 2. 이름만 다른 중복은 내린다 ─────────────────────────────
update public.services set is_active = false
 where name like '풋 테라피%'        -- = 다리 마사지
    or name like '헤드 테라피%'      -- = 머리 마사지
    or name like '어깨·목 마사지%'   -- = 목·어깨 테라피
    or name like '태국식 마사지%'    -- = 타이 마사지
    or name like '아로마 마사지%';   -- = 아로마테라피

-- ── 3. 없던 120분을 채운다 ───────────────────────────────────
-- 지금은 앱이 120분을 고르면 조용히 60분짜리를 잡아 더 싸게 예약된다. 그 구멍을 막는다.
insert into public.services (category, massage_type, name, duration_min, price_vnd, is_active)
select 'massage', 'swedish', '스웨디시 120분', 120, 700000, true
 where not exists (select 1 from public.services
                    where massage_type = 'swedish' and duration_min = 120);
insert into public.services (category, massage_type, name, duration_min, price_vnd, is_active)
select 'massage', 'thai', '타이 마사지 120분', 120, 700000, true
 where not exists (select 1 from public.services
                    where massage_type = 'thai' and duration_min = 120);

commit;

-- ── 확인 ─────────────────────────────────────────────────────
select massage_type::text as 종류, count(*) as 개수,
       string_agg(duration_min::text || '분 ' || price_vnd, ' · ' order by duration_min) as 구성
  from public.services
 where category = 'massage' and is_active
 group by 1 order by 1;

select '종류 없는 활성 마사지 = ' || count(*) as 확인
  from public.services where category = 'massage' and is_active and massage_type is null;

select '활성 ' || count(*) filter (where is_active)
    || ' · 내림 ' || count(*) filter (where not is_active) as 전체
  from public.services;
