-- profiles 자기 권한 상승 차단: 로그인 사용자는 이름·전화·성별·국적·약관동의만 고칠 수 있고, role·노쇼/취소 제재는 서버만 바꾼다.
--
-- 왜: 테이블 단위 UPDATE 권한 + profiles_self_update(컬럼 제한 없음) 때문에 누구나
--     자기 role 을 'admin' 으로 바꿔 is_admin() 을 통과하거나, cancel_count·no_show_count·
--     booking_blocked_until 을 지워 예약 제한을 풀 수 있었다.
--
-- 앱이 실제로 profiles 에 쓰는 경로 (index.html·admin.html 전수 조사, 2026-10-08)
--   editField            full_name, phone, gender, nationality       → 계속 허용
--   국적 선택             nationality                                 → 계속 허용
--   약관 동의             terms_agreed_at, privacy_agreed_at, marketing_agreed_at, terms_version → 계속 허용
--   applyCustomerPenalty 자기 cancel_count, booking_blocked_until    → RPC 로 이전
--   markNoShow(파트너)    손님의 no_show_count, cancel_count, booking_blocked_until → RPC 로 이전
--                         (원래도 RLS 가 남의 행 수정을 막아 조용히 실패하던 경로)
--   unblockCustomer(관리자) 남의 제재 해제 → 원래도 RLS 로 막혀 있었다. 이번에 손대지 않는다.
--   INSERT 경로는 없다(profiles 행은 서버가 만든다) → INSERT 권한은 다시 주지 않는다.
--
-- 테이블 단위 권한이 있으면 컬럼 단위 revoke 가 먹지 않으므로, 테이블 권한을 거두고 허용 컬럼만 다시 준다.

begin;

revoke insert, update on table public.profiles from anon, authenticated;
grant update (full_name, phone, gender, nationality,
              terms_agreed_at, privacy_agreed_at, marketing_agreed_at, terms_version)
  on table public.profiles to authenticated;

-- 제재 재계산은 서버가 예약 기록으로 직접 센다. 규칙은 앱의 CANCEL_RULES 와 같다
-- (최근 30일, 예약 1시간 전 이내 취소 또는 노쇼를 1회로, 5회 이상이면 7일 예약 제한).
-- 부를 수 있는 사람: 본인, 그 손님의 예약을 맡은 마사지사(profile_id·owner_id), 관리자.
create or replace function public.refresh_customer_penalty(p_customer uuid)
returns integer
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  n  integer;
  ns integer;
begin
  if auth.uid() is null then
    raise exception 'not authenticated' using errcode = '42501';
  end if;
  if p_customer <> auth.uid()
     and not public.is_admin()
     and not exists (
       select 1 from bookings b join providers pr on pr.id = b.provider_id
        where b.customer_id = p_customer
          and (pr.profile_id = auth.uid() or pr.owner_id = auth.uid())) then
    raise exception '권한이 없습니다.' using errcode = '42501';
  end if;

  select count(*) filter (where no_show_at is not null
                            or (cancelled_at is not null and scheduled_at - cancelled_at < interval '1 hour')),
         count(*) filter (where no_show_at is not null)
    into n, ns
    from (select no_show_at, cancelled_at, scheduled_at
            from bookings
           where customer_id = p_customer and created_at >= now() - interval '30 days'
           limit 200) b;

  update profiles
     set cancel_count = n,
         no_show_count = ns,
         booking_blocked_until = case when n >= 5 then now() + interval '7 days' else booking_blocked_until end
   where id = p_customer;
  return n;
end $$;

revoke all on function public.refresh_customer_penalty(uuid) from public, anon;
grant execute on function public.refresh_customer_penalty(uuid) to authenticated;

commit;
