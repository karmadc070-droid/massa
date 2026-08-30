-- 토스 결제 전 구간 검증용 임시 예약 1건을 만든다 (테스트 후 지운다)
-- 사용법: 이 파일을 psql 로 실행하면 booking id 를 출력한다
INSERT INTO public.bookings (booking_no, customer_id, provider_id, service_id, scheduled_at,
                             location_type, hotel_name, room_number, status, payment_method, amount_vnd)
SELECT 'TEST-TOSS-' || to_char(now(), 'HH24MISS'),
       u.id,
       (SELECT id FROM public.providers LIMIT 1),
       (SELECT id FROM public.services LIMIT 1),
       now() + interval '1 day',
       'hotel', 'TOSS TEST HOTEL', '9999', 'confirmed', 'card_onsite', 750000
  FROM auth.users u WHERE u.email = 'karmadc070@gmail.com'
RETURNING id AS booking_id, booking_no, amount_vnd;
