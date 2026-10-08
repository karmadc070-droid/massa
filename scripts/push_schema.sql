-- 아이폰 푸시 알림: 기기 토큰 저장 + 예약 이벤트·공지를 notifications 에 쌓고 send-push 함수가 APNs 로 보낸다
-- 적용: scripts/vps-apply-push.sh (여러 번 돌려도 결과가 같다)

-- ── 1. 기기 토큰 ─────────────────────────────────────
-- lang 은 앱 화면 언어(ko·vi·en·zh·ja). 푸시 제목을 그 언어로 쓴다.
create table if not exists public.push_tokens (
  token text primary key check (length(token) between 32 and 4096),
  user_id uuid not null references public.profiles (id) on delete cascade,
  platform text not null check (platform in ('ios')),
  lang text not null default 'vi' check (lang in ('ko', 'vi', 'en', 'zh', 'ja')),
  updated_at timestamptz not null default now()
);
create index if not exists push_tokens_user_id_idx on public.push_tokens (user_id);

-- 정책 없음: 앱은 아래 함수로만 등록·해제하고, 발송 함수는 service_role 로 읽는다(남의 토큰이 보일 길을 만들지 않는다).
alter table public.push_tokens enable row level security;
revoke all on public.push_tokens from anon, authenticated;

-- 같은 기기에서 계정을 바꾸면 토큰의 주인이 새 계정으로 옮겨진다.
create or replace function public.register_push_token(p_token text, p_platform text, p_lang text)
returns void language sql security definer set search_path = '' as $$
  insert into public.push_tokens (token, user_id, platform, lang)
  values (p_token, auth.uid(), p_platform, p_lang)
  on conflict (token) do update
    set user_id = excluded.user_id, platform = excluded.platform, lang = excluded.lang, updated_at = now();
$$;

-- 로그아웃할 때 본인 토큰만 지운다.
create or replace function public.unregister_push_token(p_token text)
returns void language sql security definer set search_path = '' as $$
  delete from public.push_tokens where token = p_token and user_id = auth.uid();
$$;

revoke execute on function public.register_push_token(text, text, text) from public, anon;
revoke execute on function public.unregister_push_token(text) from public, anon;
grant execute on function public.register_push_token(text, text, text) to authenticated;
grant execute on function public.unregister_push_token(text) to authenticated;

-- ── 2. notifications 를 푸시 대기열로 쓴다 ──────────────
-- pushed_at 이 비어 있으면 아직 푸시를 안 보낸 알림이다. booking_id 는 알림을 눌렀을 때 열 예약.
alter table public.notifications add column if not exists pushed_at timestamptz;
alter table public.notifications add column if not exists booking_id uuid references public.bookings (id) on delete set null;
-- 이미 있던 알림은 보낸 것으로 친다(배포 직후 옛 알림이 한꺼번에 가지 않게).
update public.notifications set pushed_at = created_at where pushed_at is null;

-- 발송 함수 전용: 안 보낸 알림을 "보냄"으로 표시하며 돌려준다.
-- 표시와 조회를 한 번에 해서, 발송이 겹쳐 돌아도 같은 알림이 두 번 가지 않는다.
-- 한 시간 넘게 묵은 알림은 보내지 않는다(서버가 오래 멈췄다 살아났을 때 철 지난 푸시가 쏟아지지 않게).
create or replace function public.claim_unpushed_notifications()
returns setof public.notifications language sql security definer set search_path = '' as $$
  update public.notifications set pushed_at = now()
  where pushed_at is null and user_id is not null and created_at > now() - interval '1 hour'
  returning *;
$$;
revoke execute on function public.claim_unpushed_notifications() from public, anon, authenticated;
grant execute on function public.claim_unpushed_notifications() to service_role;

-- ── 3. 예약 이벤트 → 알림 ─────────────────────────────
-- 새 예약: 마사지사 계정(owner_id·profile_id)과 관리자 전원에게.
-- 상태 변경: 손님에게. 확정·출발·완료, 그리고 손님 본인이 하지 않은 취소(거절·노쇼·관리자 취소).
-- 손님 본인 취소는 거꾸로 마사지사 계정에게.
-- 제목은 index.html DICT 에 있는 한국어 문장 그대로 넣는다 — 알림 화면에서 그 사람 언어로 번역된다.
-- 본문은 예약번호·시각(하노이)만 넣어 언어와 무관하게 읽힌다.
create or replace function public.notify_booking_event()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_body text := new.booking_no || ' · ' || to_char(new.scheduled_at at time zone 'Asia/Ho_Chi_Minh', 'MM/DD HH24:MI');
  v_kind text;
  v_title text;
begin
  if tg_op = 'INSERT' then
    insert into notifications (user_id, title, body, kind, booking_id)
    select u, '새 예약이 들어왔습니다', v_body, 'booking_new', new.id
    from (select owner_id as u from providers where id = new.provider_id
          union select profile_id from providers where id = new.provider_id
          union select id from profiles where role = 'admin') r
    where u is not null;
    return new;
  end if;

  if new.status is not distinct from old.status then return new; end if;
  if new.status = 'confirmed' then
    v_kind := 'booking_confirmed';  v_title := '예약이 확정되었습니다';
  elsif new.status = 'on_the_way' then
    v_kind := 'booking_on_the_way'; v_title := '테라피스트가 출발했습니다';
  elsif new.status = 'completed' then
    v_kind := 'booking_completed';  v_title := '서비스가 완료되었습니다. 평가를 남겨주세요';
  elsif new.status = 'cancelled' and coalesce(new.cancelled_by, '') <> 'customer' then
    v_kind := 'booking_cancelled';  v_title := '예약이 취소되었습니다.';
  elsif new.status = 'cancelled' then
    -- 손님 본인 취소는 마사지사 계정(owner_id·profile_id — 새 예약 알림과 같은 대상)에 알린다
    insert into notifications (user_id, title, body, kind, booking_id)
    select u, '손님이 예약을 취소했습니다', v_body, 'booking_cancelled_by_customer', new.id
    from (select owner_id as u from providers where id = new.provider_id
          union select profile_id from providers where id = new.provider_id) r
    where u is not null;
    return new;
  else
    return new;
  end if;
  insert into notifications (user_id, title, body, kind, booking_id)
  values (new.customer_id, v_title, v_body, v_kind, new.id);
  return new;
end $$;

drop trigger if exists trg_notify_booking_insert on public.bookings;
create trigger trg_notify_booking_insert
  after insert on public.bookings
  for each row execute function public.notify_booking_event();
drop trigger if exists trg_notify_booking_status on public.bookings;
create trigger trg_notify_booking_status
  after update of status on public.bookings
  for each row execute function public.notify_booking_event();

-- ── 4. 관리자 공지 ────────────────────────────────────
-- 전 회원의 알림함에 넣는다. 푸시는 토큰이 있는 사람(아이폰 앱 로그인)에게만 간다.
create or replace function public.send_notice(p_title text, p_body text)
returns integer language plpgsql security definer set search_path = public as $$
declare n integer;
begin
  if not public.is_admin() then
    raise exception '관리자만 공지를 보낼 수 있습니다' using errcode = '42501';
  end if;
  if coalesce(trim(p_title), '') = '' then raise exception '제목을 입력하세요'; end if;
  insert into notifications (user_id, title, body, kind)
  select id, trim(p_title), nullif(trim(p_body), ''), 'notice' from profiles;
  get diagnostics n = row_count;
  return n;
end $$;
revoke execute on function public.send_notice(text, text) from public, anon;
grant execute on function public.send_notice(text, text) to authenticated;

-- ── 5. 알림이 생기면 곧바로 발송 함수를 깨운다 ─────────────
-- 입금 알림(notify_trigger.sql)과 같은 방식: URL·시크릿은 app_settings('push') 에서 읽는다.
-- 문장 단위 트리거라 공지 한 번에 호출도 한 번이다. pg_net 은 커밋된 뒤에 요청을 보낸다.
-- 호출이 빠지더라도 VPS 크론이 1분마다 같은 함수를 부르므로 늦게라도 나간다.
create or replace function public.kick_send_push()
returns trigger language plpgsql security definer set search_path = public as $$
declare cfg jsonb;
begin
  select value into cfg from app_settings where key = 'push';
  if coalesce(cfg->>'url', '') = '' then return null; end if;
  begin
    perform net.http_post(
      url     := cfg->>'url',
      headers := jsonb_build_object('Content-Type', 'application/json', 'x-notify-secret', coalesce(cfg->>'secret', '')),
      body    := '{}'::jsonb,
      timeout_milliseconds := 5000
    );
  exception when others then
    raise warning '푸시 발송 호출 실패: %', sqlerrm;
  end;
  return null;
end $$;

drop trigger if exists trg_kick_send_push on public.notifications;
create trigger trg_kick_send_push
  after insert on public.notifications
  for each statement execute function public.kick_send_push();

-- 발송 함수 주소와 시크릿. 시크릿은 입금 알림과 같은 NOTIFY_SECRET 을 쓴다(값을 화면에 꺼내지 않고 복사).
insert into public.app_settings (key, value, updated_at)
select 'push', jsonb_build_object('url', 'http://massa-edge-functions:9000/send-push', 'secret', value->>'secret'), now()
from public.app_settings where key = 'notify'
on conflict (key) do update set value = excluded.value, updated_at = now();

select 'push schema ok' as result;
