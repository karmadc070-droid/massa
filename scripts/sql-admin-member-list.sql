-- 관리자 전용 가입자 목록. 지금 /admin 에는 '회원 N명' 숫자만 있고 명단이 없다.
--
-- 보안 설계
--   SECURITY DEFINER 로 만들되 첫 줄에서 is_admin() 을 검사한다.
--   검사를 빼먹으면 누구나 전 회원의 전화번호를 가져갈 수 있다. 이 한 줄이 전부다.
--   search_path 를 고정하는 것도 같은 이유다 (SECURITY DEFINER 함수의 기본 수칙).
--
-- 이메일은 profiles 에 없고 auth.users 에 있다. 그래서 조인한다.

create or replace function public.admin_member_list(
  p_q      text default null,   -- 이름·이메일·전화 부분 검색
  p_role   text default null,   -- 'customer' | 'admin' | 'reviewer' | null(전체)
  p_limit  int  default 200,
  p_offset int  default 0
)
returns table (
  id              uuid,
  full_name       text,
  email           text,
  phone           text,
  role            text,
  nationality     text,
  lang            text,
  created_at      timestamptz,
  last_sign_in_at timestamptz,
  bookings        bigint,
  cancel_count    int,
  no_show_count   int,
  blocked_until   timestamptz,
  is_provider     boolean
)
language plpgsql
security definer
set search_path = public, auth
as $$
begin
  if not public.is_admin() then
    raise exception '관리자만 볼 수 있습니다.' using errcode = '42501';
  end if;

  return query
  select p.id,
         p.full_name,
         u.email::text,
         p.phone,
         p.role::text,
         p.nationality,
         p.preferred_language,
         p.created_at,
         u.last_sign_in_at,
         -- 예약 테이블의 고객 칼럼은 customer_id 다 (user_id 아님. index.html 1541행에서 확인)
         (select count(*) from bookings b where b.customer_id = p.id),
         coalesce(p.cancel_count, 0),
         coalesce(p.no_show_count, 0),
         p.booking_blocked_until,
         exists (select 1 from providers pr
                  where pr.profile_id = p.id or pr.owner_id = p.id)
    from profiles p
    left join auth.users u on u.id = p.id
   where (p_role is null or p.role::text = p_role)
     and (p_q is null or p_q = '' or
          coalesce(p.full_name,'') ilike '%'||p_q||'%' or
          coalesce(u.email::text,'') ilike '%'||p_q||'%' or
          coalesce(p.phone,'')      ilike '%'||p_q||'%')
   order by p.created_at desc
   limit  greatest(1, least(p_limit, 500))
  offset greatest(0, p_offset);
end $$;

-- 로그인한 사람만 호출할 수 있게 하고, 실제 차단은 함수 안의 is_admin() 이 한다.
revoke all on function public.admin_member_list(text, text, int, int) from public, anon;
grant execute on function public.admin_member_list(text, text, int, int) to authenticated;

comment on function public.admin_member_list(text, text, int, int) is
  '관리자 전용 가입자 목록. is_admin() 을 통과해야만 결과를 돌려준다.';
