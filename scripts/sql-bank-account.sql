-- 회사 입금 계좌를 설정값으로 둔다.
--
-- 왜 코드에 안 박나 — 계좌가 바뀌면 앱을 새로 빌드해서 심사까지 받아야 한다.
--   설정값으로 두면 DB 한 줄만 고치면 모든 화면이 따라온다.
--
-- 왜 app_settings 인가 — 이미 수수료율·가격이 여기 있다. 설정이 두 군데로 갈라지면
--   어느 쪽이 맞는지 아무도 모르게 된다.
--
-- 읽기 권한 — settings_read 정책이 `TO authenticated` 다.
--   로그인한 사람만 본다. 예약 결제 화면도, 마사지사 입금 화면도 로그인 뒤라서 맞는다.
--   로그인 안 한 사람에게 계좌를 보여 줄 이유가 없다.

insert into public.app_settings (key, value, updated_at)
values ('bank', jsonb_build_object(
  'bank',    'Shinhan Bank',
  'account', '700-008-223800',
  'holder',  'PARK DONG CHUN'
), now())
on conflict (key) do update
  set value = excluded.value, updated_at = now();

select key, jsonb_pretty(value) from public.app_settings where key = 'bank';
