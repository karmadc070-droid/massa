-- 입금 신고가 들어오면 관리자에게 메일이 나가도록 DB 에서 직접 호출한다.
-- 클라이언트가 호출하게 하면 앱이 죽거나 우회했을 때 알림이 빠진다. pg_net 으로 서버에서 쏜다.
-- 적용: scripts/vps-apply-notify.sh

create extension if not exists pg_net;

-- 함수 URL·시크릿은 코드에 박지 않고 설정 테이블에서 읽는다.
-- app_settings 는 RLS 로 관리자만 읽으므로 값이 노출되지 않는다.
insert into public.app_settings (key, value, updated_at)
values ('notify', '{"url": "http://massa-edge-functions:9000/notify-admin", "secret": ""}'::jsonb, now())
on conflict (key) do nothing;

create or replace function public.notify_deposit_reported()
returns trigger language plpgsql security definer set search_path = public as $$
declare cfg jsonb; u text; s text;
begin
  select value into cfg from public.app_settings where key = 'notify';
  u := coalesce(cfg->>'url', '');
  s := coalesce(cfg->>'secret', '');
  if u = '' then return new; end if;

  -- 실패해도 입금 신고 자체는 저장돼야 한다. 알림은 부수적인 일이다.
  begin
    perform net.http_post(
      url     := u,
      headers := jsonb_build_object('Content-Type', 'application/json', 'x-notify-secret', s),
      body    := jsonb_build_object('action', 'deposit_reported', 'deposit_id', new.id),
      timeout_milliseconds := 5000
    );
  exception when others then
    raise warning '입금 알림 전송 실패: %', sqlerrm;
  end;
  return new;
end $$;

drop trigger if exists trg_notify_deposit on public.provider_deposit;
create trigger trg_notify_deposit
  after insert on public.provider_deposit
  for each row when (new.status = 'reported')
  execute function public.notify_deposit_reported();

select 'notify trigger ok' as result;
