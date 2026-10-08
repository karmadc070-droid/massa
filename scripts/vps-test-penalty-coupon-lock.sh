#!/bin/sh
# 거절 제재 회복·하한과 쿠폰함 잠금을 실제 REST 로 확인한다. 임시 계정 3개(손님·마사지사·관리자)를 만들고 끝에 지운다.
# 키·토큰은 출력하지 않는다. 시험 예약은 session_replication_role=replica 로 넣어 새 예약 알림을 만들지 않는다.
E=/root/massa/.env
U=$(grep '^SUPABASE_PUBLIC_URL=' $E | cut -d= -f2- | tr -d '"\r')
A=$(grep '^ANON_KEY=' $E | cut -d= -f2- | tr -d '"\r')
S=$(grep '^SERVICE_ROLE_KEY=' $E | cut -d= -f2- | tr -d '"\r')
PW="Tmp-$(head -c12 /dev/urandom | od -An -tx1 | tr -d ' \n')"
q() { docker exec massa-db psql -U postgres -d postgres -Atc "$1"; }
T0=$(q "select now()")
mk() { curl -s -X POST "$U/auth/v1/admin/users" -H "apikey: $S" -H "Authorization: Bearer $S" -H 'Content-Type: application/json' \
         -d "{\"email\":\"$1\",\"password\":\"$PW\",\"email_confirm\":true}" | sed -n 's/^{"id":"\([^"]*\)".*/\1/p'; }
tok() { curl -s -X POST "$U/auth/v1/token?grant_type=password" -H "apikey: $A" -H 'Content-Type: application/json' \
          -d "{\"email\":\"$1\",\"password\":\"$PW\"}" | sed -n 's/.*"access_token":"\([^"]*\)".*/\1/p'; }
call() {
  out=$(curl -s -o /tmp/pen_body -w '%{http_code}' -X "$2" "$U/rest/v1/$3" -H "apikey: $A" -H "Authorization: Bearer $1" \
        -H 'Content-Type: application/json' -H 'Prefer: return=representation' -d "$4")
  if [ "$out" = "$5" ]; then r=PASS; else r=FAIL; fi
  echo "$r [$out] $6 :: $(head -c 130 /tmp/pen_body)"
}

C=$(mk pen-rest-c@test.massa); P=$(mk pen-rest-p@test.massa); AD=$(mk pen-rest-a@test.massa)
q "update profiles set role='admin' where id='$AD'" >/dev/null
TC=$(tok pen-rest-c@test.massa); TP=$(tok pen-rest-p@test.massa); TA=$(tok pen-rest-a@test.massa)
echo "temp users: ${#C}/${#P}/${#AD} chars, tokens: ${#TC}/${#TP}/${#TA} chars"

# 쿠폰함
OK=$(q "select id from coupons where is_active and (valid_until is null or valid_until >= current_date) and coalesce(min_amount_vnd,0) <= 500000 order by created_at limit 1")
OLD=$(q "select id from coupons where valid_until < current_date limit 1")
call "$TC" POST user_coupons "{\"customer_id\":\"$C\",\"coupon_id\":\"$OLD\"}" 403 "손님: 기한 지난 쿠폰 받기 거부"
call "$TC" POST user_coupons "{\"customer_id\":\"$C\",\"coupon_id\":\"$OK\",\"is_used\":true}" 403 "손님: 사용됨 상태로 받기 거부"
call "$TC" POST user_coupons "{\"customer_id\":\"$C\",\"coupon_id\":\"$OK\"}" 201 "손님: 쿠폰 받기"
X=$(q "insert into providers (profile_id, display_name, application_status, is_active) values ('$P','pen rest','approved',true) returning id" | grep -E '^[0-9a-f-]{36}$')
B=$(docker exec massa-db psql -U postgres -d postgres -Atc "set session_replication_role = replica; insert into bookings (customer_id, provider_id, scheduled_at, location_type, status, payment_method, amount_vnd) values ('$C','$X', now() + interval '1 day', 'hotel', 'confirmed', 'card_onsite', 500000) returning id" | grep -E '^[0-9a-f-]{36}$')
call "$TC" PATCH "bookings?id=eq.$B" "{\"coupon_id\":\"$OK\",\"discount_vnd\":1}" 200 "손님: 예약에 쿠폰 적용"
echo "쿠폰 자동 사용 처리: $(q "select is_used from user_coupons where customer_id='$C' and coupon_id='$OK'") / 할인액: $(q "select discount_vnd from bookings where id='$B'")"
call "$TC" PATCH "user_coupons?customer_id=eq.$C&coupon_id=eq.$OK&is_used=eq.false" '{"is_used":true}' 200 "손님: 구 앱 사용 처리(0행, 오류 없음)"
call "$TC" PATCH "user_coupons?customer_id=eq.$C" '{"is_used":false,"used_at":null}' 403 "손님: 미사용으로 되돌리기 거부"
call "$TC" DELETE "user_coupons?customer_id=eq.$C" '' 403 "손님: 쿠폰함 삭제 거부"

# 거절 제재
q "update providers set penalty_level = 2, reject_count = 9 where id='$X'" >/dev/null
call "$TP" POST "rpc/refresh_provider_penalty" "{\"p_provider\":\"$X\"}" 200 "마사지사: 옛 거절 없음 → 0단계로 회복"
call "$TA" PATCH "providers?id=eq.$X" '{"penalty_level":1}' 200 "관리자: 신고 제재 1단계"
call "$TP" POST "rpc/refresh_provider_penalty" "{\"p_provider\":\"$X\",\"p_after_reject\":true}" 200 "마사지사: 재계산(하한 1 유지)"
call "$TP" PATCH "providers?id=eq.$X" '{"penalty_floor":0}' 403 "마사지사: 하한 지우기 거부"
call "$TP" POST "rpc/refresh_all_provider_penalties" '{}' 403 "마사지사: 전체 재계산 호출 거부"
echo "결과 단계/하한: $(q "select penalty_level||'/'||penalty_floor from providers where id='$X'") (1/1 이어야 함)"

echo "실제 사용자에게 간 알림(0이어야 함): $(q "select count(*) from notifications where created_at >= '$T0' and user_id not in ('$C','$P','$AD')")"

q "delete from notifications where user_id in ('$C','$P','$AD'); delete from bookings where customer_id='$C'; delete from providers where id='$X'" >/dev/null
for id in $C $P $AD; do curl -s -o /dev/null -w "delete user %{http_code}\n" -X DELETE "$U/auth/v1/admin/users/$id" -H "apikey: $S" -H "Authorization: Bearer $S"; done
echo "남은 행(모두 0): users=$(q "select count(*) from auth.users where email like 'pen-rest-%'") profiles=$(q "select count(*) from profiles where id in ('$C','$P','$AD')") user_coupons=$(q "select count(*) from user_coupons where customer_id='$C'") providers=$(q "select count(*) from providers where id='$X'") bookings=$(q "select count(*) from bookings where customer_id='$C'") notis=$(q "select count(*) from notifications where user_id in ('$C','$P','$AD')")"
rm -f /tmp/pen_body
