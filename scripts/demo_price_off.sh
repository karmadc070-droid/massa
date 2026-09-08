#!/bin/sh
# 화면 확인용으로 넣었던 개인 가격을 지운다.
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
delete from public.provider_price;
select '남은 개인 가격 ' || count(*) || '건' as 확인 from public.provider_price;
select public.public_provider_prices() as 공개목록;
PSQL
