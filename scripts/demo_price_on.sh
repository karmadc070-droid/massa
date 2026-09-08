#!/bin/sh
# 화면 확인용으로 개인 가격 한 건을 승인 상태로 넣는다. 확인이 끝나면 demo_price_off.sh 로 지운다.
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
select id as pv1 from public.providers where display_name='Mai H.' and application_status='approved' limit 1 \gset
select id as sv1 from public.services where name='아로마테라피 60분' and is_active limit 1 \gset
insert into public.provider_price (provider_id, service_id, price_vnd, reviewed_at)
values (:'pv1', :'sv1', 650000, now())
on conflict (provider_id, service_id) do update set price_vnd = 650000, pending_vnd = null;
select '마사지사 ' || left((:'pv1')::text,8) || ' · 코스 ' || left((:'sv1')::text,8) || ' → 650,000₫' as 넣음;
select public.public_provider_prices() as 공개목록;
PSQL
