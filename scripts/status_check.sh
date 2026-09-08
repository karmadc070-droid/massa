#!/bin/sh
# 지금 처리해야 할 것들의 실제 상태를 한 번에 본다.
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
\echo '=== 고객에게 보이는 마사지사 (is_active + approved) ==='
select case when coalesce(p.profile_id, p.owner_id) is null then '계정 없음 (시드)'
            else '계정 있음' end as 구분,
       count(*) as 명수,
       string_agg(p.display_name, ', ' order by p.display_name) as 명단
  from public.providers p
 where p.is_active and p.application_status = 'approved'
 group by 1 order by 2 desc;

\echo '=== 예약 가능한 코스가 안 붙은 마사지사 ==='
select p.display_name as 이름,
       case when coalesce(p.profile_id,p.owner_id) is null then '시드' else '실제 계정' end as 구분
  from public.providers p
 where p.is_active and p.application_status = 'approved'
   and not exists (select 1 from public.provider_services ps where ps.provider_id = p.id);

\echo '=== 신분증·계좌가 없는 승인 마사지사 (정산 못 함) ==='
select p.display_name as 이름,
       case when k.provider_id is null then '서류 자체 없음'
            else concat_ws(' · ',
              case when k.id_front_url is null then '신분증앞 없음' end,
              case when k.bank_account is null then '계좌 없음' end) end as 빠진것
  from public.providers p
  left join public.provider_kyc k on k.provider_id = p.id
 where p.is_active and p.application_status = 'approved'
   and coalesce(p.profile_id, p.owner_id) is not null
   and (k.provider_id is null or k.id_front_url is null or k.bank_account is null);

\echo '=== 코스 연결 상태 (스웨디시·타이 120분이 빠져 있는지) ==='
select s.name as 코스, count(ps.provider_id) as 연결된_마사지사
  from public.services s
  left join public.provider_services ps on ps.service_id = s.id
 where s.is_active and s.duration_min = 120 and s.category = 'massage'
 group by 1 order by 2, 1;

\echo '=== 개인 가격 현황 ==='
select count(*) filter (where price_vnd is not null) as 적용중,
       count(*) filter (where pending_vnd is not null) as 승인대기
  from public.provider_price;

\echo '=== 실제 예약·매출 (오픈 전이라 0 이면 정상) ==='
select status::text as 상태, count(*), coalesce(sum(amount_vnd),0) as 금액
  from public.bookings group by 1 order by 2 desc;
PSQL
