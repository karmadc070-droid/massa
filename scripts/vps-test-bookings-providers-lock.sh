#!/bin/sh
# 예약·제공자 권한 잠금을 실제 REST 로 확인한다. 임시 계정 2개를 만들고 끝에 지운다. 키·토큰은 출력하지 않는다.
# 실제 사용자에게 알림이 가지 않게: 시험 예약은 session_replication_role=replica 로 넣어 새 예약 알림 트리거를 건너뛰고,
# 손님 취소 알림은 담당 마사지사(=임시 계정)에게만 간다.
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
# call <토큰> <메서드> <경로> <본문> <기대코드> <이름>
call() {
  out=$(curl -s -o /tmp/lock_body -w '%{http_code}' -X "$2" "$U/rest/v1/$3" -H "apikey: $A" -H "Authorization: Bearer $1" \
        -H 'Content-Type: application/json' -H 'Prefer: return=representation' -d "$4")
  if [ "$out" = "$5" ]; then r=PASS; else r=FAIL; fi
  echo "$r [$out] $6 :: $(head -c 150 /tmp/lock_body)"
}

C=$(mk lock-rest-c@test.massa); P=$(mk lock-rest-p@test.massa)
echo "temp users created: c=${#C} p=${#P} chars"
TC=$(tok lock-rest-c@test.massa); TP=$(tok lock-rest-p@test.massa)
echo "tokens: c=${#TC} p=${#TP} chars"

call "$TP" POST providers "{\"profile_id\":\"$P\",\"display_name\":\"rest\",\"application_status\":\"approved\"}" 403 "신청자: 승인 상태로 INSERT 거부"
call "$TP" POST providers "{\"profile_id\":\"$P\",\"display_name\":\"rest\",\"application_status\":\"pending\",\"is_verified\":true}" 403 "신청자: 인증 켠 INSERT 거부"
call "$TP" POST providers "{\"profile_id\":\"$P\",\"kind\":\"masseur\",\"display_name\":\"rest\",\"specialties\":[\"aroma\"],\"is_active\":false,\"application_status\":\"pending\",\"rating\":0,\"review_count\":0}" 201 "신청자: 정상 신청 INSERT"
X=$(sed -n 's/^\[{"id":"\([^"]*\)".*/\1/p' /tmp/lock_body)
q "update providers set application_status='approved' where id='$X'" >/dev/null
call "$TP" PATCH "providers?id=eq.$X" '{"is_verified":true}' 403 "마사지사: 인증 켜기 거부"
call "$TP" PATCH "providers?id=eq.$X" '{"fee_tier":"freelancer","penalty_level":0}' 403 "마사지사: 등급·제재 변경 거부"
call "$TP" PATCH "providers?id=eq.$X" '{"display_name":"rest ok","bio":"b","business_hours":"10:00 ~ 22:00","is_active":true}' 200 "마사지사: 프로필·영업시간 수정"
call "$TP" POST "rpc/refresh_provider_penalty" "{\"p_provider\":\"$X\"}" 200 "마사지사: 거절 누적 재계산 RPC"
call "$TC" POST "rpc/refresh_provider_penalty" "{\"p_provider\":\"$X\"}" 403 "손님: 남의 제재 재계산 거부"

SV=$(q "select id from services limit 1")
B=$(docker exec massa-db psql -U postgres -d postgres -Atc "set session_replication_role = replica; insert into bookings (customer_id, provider_id, service_id, scheduled_at, location_type, status, payment_method, amount_vnd) values ('$C','$X','$SV', now() + interval '1 day', 'hotel', 'confirmed', 'card_onsite', 500000) returning id" | grep -E '^[0-9a-f-]{36}$')
call "$TC" PATCH "bookings?id=eq.$B" '{"is_paid":true}' 403 "손님: 결제 완료 표시 거부"
call "$TC" PATCH "bookings?id=eq.$B" '{"amount_vnd":1}' 403 "손님: 금액 변경 거부"
call "$TC" PATCH "bookings?id=eq.$B" '{"payment_method":"card_onsite","is_paid":false,"amount_vnd":500000}' 200 "손님: 현장 결제 확정(구 앱 모양)"
call "$TP" PATCH "bookings?id=eq.$B" '{"amount_vnd":1}' 403 "마사지사: 예약 금액 변경 거부"
call "$TC" PATCH "bookings?id=eq.$B" '{"status":"cancelled","cancelled_at":"2020-01-01T00:00:00Z","cancel_reason":"rest","cancelled_by":"customer"}' 200 "손님: 취소"
echo "취소 시각이 서버 시각인가: $(q "select cancelled_at > now() - interval '1 minute' from bookings where id='$B'")"

q "update profiles set booking_blocked_until = now() + interval '1 day' where id='$C'" >/dev/null
call "$TC" POST bookings "{\"customer_id\":\"$C\",\"provider_id\":\"$X\",\"service_id\":\"$SV\",\"scheduled_at\":\"2030-01-01T10:00:00Z\",\"location_type\":\"hotel\",\"status\":\"confirmed\",\"payment_method\":\"card_onsite\",\"amount_vnd\":500000}" 403 "제한 손님: 예약 거부"

echo "실제 사용자에게 간 알림(0이어야 함): $(q "select count(*) from notifications where created_at >= '$T0' and user_id not in ('$C','$P')")"

# 정리
q "delete from notifications where user_id in ('$C','$P'); delete from bookings where customer_id='$C'; delete from provider_kyc where provider_id='$X'; delete from providers where id='$X'" >/dev/null
for id in $C $P; do curl -s -o /dev/null -w "delete user %{http_code}\n" -X DELETE "$U/auth/v1/admin/users/$id" -H "apikey: $S" -H "Authorization: Bearer $S"; done
echo "남은 행(모두 0): users=$(q "select count(*) from auth.users where email like 'lock-rest-%'") profiles=$(q "select count(*) from profiles where id in ('$C','$P')") providers=$(q "select count(*) from providers where id='$X'") bookings=$(q "select count(*) from bookings where customer_id='$C'") notis=$(q "select count(*) from notifications where user_id in ('$C','$P')")"
rm -f /tmp/lock_body
