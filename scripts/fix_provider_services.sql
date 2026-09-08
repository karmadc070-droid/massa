-- 예약 가능한 코스가 빠져 있는 것을 채운다.
--
-- 1) Kun 은 승인됐는데 provider_services 가 0건이라 프로필에 '등록된 서비스가 없습니다' 가 뜬다.
--    본인이 고른 전문분야(specialties)에 해당하는 코스를 붙인다.
-- 2) 스웨디시 120분·타이 마사지 120분은 아무에게도 안 붙어 있다.
--    나중에 코스를 추가하면서 연결을 빠뜨렸다. 같은 종류의 60·90분을 하는 사람에게 붙인다.

begin;

-- ── 1. Kun ──────────────────────────────────────────────────
insert into public.provider_services (provider_id, service_id)
select p.id, s.id
  from public.providers p
  join public.services s
    on s.is_active
   and s.category = 'massage'
   and s.massage_type::text = any (p.specialties)
 where p.display_name = 'Kun' and p.application_status = 'approved'
on conflict do nothing;

-- ── 2. 빠진 120분 ───────────────────────────────────────────
-- 같은 종류를 이미 하는 사람에게만 붙인다. 안 하던 종류를 새로 떠안기지 않는다.
insert into public.provider_services (provider_id, service_id)
select distinct ps.provider_id, s120.id
  from public.provider_services ps
  join public.services s     on s.id = ps.service_id and s.is_active
  join public.services s120  on s120.is_active
                            and s120.massage_type = s.massage_type
                            and s120.duration_min = 120
 where s.duration_min in (60, 90)
on conflict do nothing;

commit;

-- ── 확인 ─────────────────────────────────────────────────────
select 'Kun 연결된 코스' as 항목, count(*)::text as 값
  from public.provider_services ps
  join public.providers p on p.id = ps.provider_id
 where p.display_name = 'Kun'
union all
select '코스가 0건인 승인 마사지사', count(*)::text
  from public.providers p
 where p.application_status = 'approved' and p.is_active
   and not exists (select 1 from public.provider_services ps where ps.provider_id = p.id);

select s.name as 코스, count(ps.provider_id) as 연결된_마사지사
  from public.services s
  left join public.provider_services ps on ps.service_id = s.id
 where s.is_active and s.duration_min = 120 and s.category = 'massage'
 group by 1 order by 2, 1;

select p.display_name as Kun이_하는_코스, string_agg(s.name, ', ' order by s.name) as 목록
  from public.providers p
  join public.provider_services ps on ps.provider_id = p.id
  join public.services s on s.id = ps.service_id
 where p.display_name = 'Kun'
 group by 1;
