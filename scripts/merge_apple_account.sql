-- 애플 로그인 신원을 사장님 구글 계정으로 옮겨 하나로 합친다.
--
-- 애플로 로그인하면 GoTrue 가 별도 auth 사용자를 만든다. 그래서 앱에서 애플로 들어가면
-- profiles.role 이 없어 운영 콘솔이 열리지 않았다.
-- 데이터를 옮기는 게 아니라 **신원(identity)만** 구글 계정 쪽으로 옮긴다.
-- 애플 계정에 딸린 데이터가 한 건이라도 있으면 중단한다 (덮어쓰면 기록이 섞인다).

do $$
declare
  v_apple uuid;
  v_goog  uuid;
  r       record;
  n       bigint;
  total   bigint := 0;
begin
  select id into v_apple from auth.users where email = 'karmadc77@icloud.com';
  select id into v_goog  from auth.users where email = 'karmadc070@gmail.com';
  if v_apple is null then raise exception '애플 계정을 찾지 못했습니다.'; end if;
  if v_goog  is null then raise exception '구글 계정을 찾지 못했습니다.'; end if;

  -- auth.users / public.profiles 를 가리키는 모든 외래키를 직접 훑는다.
  -- 표를 하나라도 빠뜨리면 지운 뒤에야 안다.
  for r in
    select c.conrelid::regclass::text as tbl, a.attname as col
      from pg_constraint c
      join pg_attribute a on a.attrelid = c.conrelid and a.attnum = c.conkey[1]
     where c.contype = 'f'
       and c.confrelid in ('auth.users'::regclass, 'public.profiles'::regclass)
       and c.conrelid::regclass::text not like 'auth.%'
  loop
    execute format('select count(*) from %s where %I = $1', r.tbl, r.col)
      into n using v_apple;
    if n > 0 then
      raise notice '  % . % : %건', r.tbl, r.col, n;
      total := total + n;
    end if;
  end loop;

  if total > 0 then
    raise exception '애플 계정에 데이터가 %건 있습니다. 합치지 않고 멈춥니다.', total;
  end if;

  -- 신원을 옮긴다. 이 뒤로 애플 로그인은 구글 계정(관리자)으로 들어온다.
  update auth.identities set user_id = v_goog, updated_at = now()
   where user_id = v_apple and provider = 'apple';

  -- 남은 빈 계정을 지운다. 세션은 먼저 끊는다.
  delete from auth.sessions        where user_id = v_apple;
  delete from auth.refresh_tokens  where user_id = v_apple::text;
  delete from auth.users           where id = v_apple;

  raise notice '합쳤습니다. 애플 신원 → %', v_goog;
end $$;

-- ── 확인 ─────────────────────────────────────────────────────
select u.email as 계정, pr.role::text as 역할,
       string_agg(i.provider, ' · ' order by i.provider) as 로그인수단
  from auth.users u
  join auth.identities i on i.user_id = u.id
  left join public.profiles pr on pr.id = u.id
 where u.email = 'karmadc070@gmail.com'
 group by 1, 2;

select case when exists (select 1 from auth.users where email = 'karmadc77@icloud.com')
            then '★ 애플 계정이 아직 남아 있다' else '빈 애플 계정 정리됨' end as 확인;
