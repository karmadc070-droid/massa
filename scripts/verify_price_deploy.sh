#!/bin/sh
# 배포된 파일에 새 코드가 실제로 들어갔는지 확인하고, 시험용 가격을 지운다.
A=/srv/massa-admin/index.html
W=/srv/massa-web/index.html

echo '=== 운영 콘솔 (admin.moahagwon.com) ==='
for s in 'id="partnerPrice"' 'id="adminPrice"' 'mpPriceRow' 'mpPriceAdminRow' \
         'owner_id.eq.' 'function priceOf' 'loadMyPrices' 'loadPriceRequests'; do
  printf '  %-22s %s\n' "$s" "$(grep -c -F "$s" "$A")"
done
printf '  %-22s %s  (0 이어야 한다)\n' '임의금액 850000' "$(grep -c -F '|| 850000' "$A")"

echo '=== 고객 앱 (massa.moahagwon.com) ==='
for s in 'function priceOf' 'public_provider_prices'; do
  printf '  %-22s %s\n' "$s" "$(grep -c -F "$s" "$W")"
done

echo '=== 시험용 가격 정리 ==='
docker exec -i massa-db psql -U postgres -d postgres <<'PSQL'
delete from public.provider_price;
select '  남은 개인 가격 ' || count(*) || '건' as 확인 from public.provider_price;
select '  공개 목록 = ' || public.public_provider_prices()::text as 확인;
PSQL
