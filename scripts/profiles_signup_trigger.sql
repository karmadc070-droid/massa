-- 가입 트리거 복구: auth.users 에 행이 생기면 profiles 행을 만들고, 빠진 회원을 백필하며, 관리자 예약 제한 해제 RPC 를 추가한다.
--
-- 왜: VPS 이전 때 auth 스키마 트리거가 따라오지 않아 handle_new_user() 함수만 있고 트리거가 0개였다.
--     8/27 이후 가입자는 profiles 행이 없어 프로필 수정·약관 동의·제재 기록이 전부 0행 처리됐다.
-- role: 메타데이터에서 절대 읽지 않는다. 컬럼 기본값(customer)만 쓴다.
--       앱의 signUp 은 메타데이터를 보내지 않고, 마사지사는 providers.profile_id 로 구분하며,
--       관리자·reviewer 는 서버에서만 바꾼다. (가입자가 options.data.role='admin' 을 보내도 무시된다)
-- profiles 에는 트리거가 없으므로 백필이 notifications·push_outbox 를 만들지 않는다.

begin;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (new.id,
          coalesce(new.raw_user_meta_data->>'full_name', new.raw_user_meta_data->>'name', ''),
          coalesce(new.phone, ''))
  on conflict (id) do nothing;
  return new;
end $$;

revoke all on function public.handle_new_user() from public, anon, authenticated;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 백필: 트리거와 같은 매핑
insert into public.profiles (id, full_name, phone)
select u.id,
       coalesce(u.raw_user_meta_data->>'full_name', u.raw_user_meta_data->>'name', ''),
       coalesce(u.phone, '')
  from auth.users u
 where not exists (select 1 from public.profiles p where p.id = u.id)
on conflict (id) do nothing;

-- 관리자 예약 제한 해제 (admin.html unblockCustomer). profiles 에 관리자 UPDATE 경로가 없어 원래 실패하던 것.
create or replace function public.admin_unblock_customer(p_customer uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
begin
  if auth.uid() is null or not public.is_admin() then
    raise exception '권한이 없습니다.' using errcode = '42501';
  end if;
  update profiles
     set booking_blocked_until = null, cancel_count = 0, no_show_count = 0
   where id = p_customer;
end $$;

revoke all on function public.admin_unblock_customer(uuid) from public, anon;
grant execute on function public.admin_unblock_customer(uuid) to authenticated;

commit;
