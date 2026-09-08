#!/bin/sh
# 개인 가격 붙이기 전에 필요한 것만 확인한다. app_settings 는 key 만 본다 (값에 시크릿이 있다).
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
\echo '=== app_settings 구조 ==='
\d public.app_settings
\echo '=== app_settings 에 있는 key (값은 보지 않는다) ==='
select key from public.app_settings order by 1;
\echo '=== bookings 트리거 ==='
select tgname from pg_trigger where tgrelid = 'public.bookings'::regclass and not tgisinternal;
\echo '=== bookings 금액 관련 칸 ==='
select column_name, data_type, is_nullable
  from information_schema.columns
 where table_schema='public' and table_name='bookings'
   and column_name in ('amount_vnd','fee_rate','service_id','provider_id','status');
\echo '=== provider_services 실제 데이터 (마사지사별 코스 수) ==='
select p.display_name, count(*) as 코스수
  from public.provider_services ps join public.providers p on p.id = ps.provider_id
 group by 1 order by 2 desc limit 10;
\echo '=== 승인된 마사지사 중 provider_services 가 하나도 없는 사람 ==='
select count(*) as 코스미등록
  from public.providers p
 where p.application_status = 'approved'
   and not exists (select 1 from public.provider_services ps where ps.provider_id = p.id);
\echo '=== services 가격 분포 (활성) ==='
select category::text, count(*), min(price_vnd), max(price_vnd)
  from public.services where is_active group by 1;
PSQL
