-- 같은 사람이 마사지사 신청을 여러 개 만들지 못하게 막는다.
-- demo 계정 하나가 2분 만에 4건을 만든 적이 있다. 앱 화면만 고치면 우회할 수 있으니 DB 에서 막는다.
--
-- 유니크 인덱스가 아니라 트리거를 쓴다. 인덱스로 걸면 이미 있는 중복(demo 계정 5건) 때문에
-- 생성 자체가 실패한다. 사장님이 기존 데이터는 그대로 두기로 했으므로 앞으로 들어오는 것만 막는다.
-- 반려(rejected)된 사람은 다시 신청할 수 있어야 하므로 대기·승인 상태만 셈에 넣는다.

create or replace function public.block_duplicate_provider()
returns trigger
language plpgsql security definer set search_path = public as $$
declare n int;
begin
  if new.profile_id is null then return new; end if;

  select count(*) into n from public.providers
   where profile_id = new.profile_id
     and application_status in ('pending', 'approved')
     and id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid);

  if n > 0 then
    raise exception '이미 등록 신청이 있습니다. 심사 결과를 기다려 주세요.'
      using errcode = '23505';
  end if;
  return new;
end $$;

drop trigger if exists trg_block_duplicate_provider on public.providers;
create trigger trg_block_duplicate_provider
  before insert on public.providers
  for each row execute function public.block_duplicate_provider();

-- ── 확인 ─────────────────────────────────────────────────────
select '트리거' as 항목,
       case when exists (select 1 from pg_trigger
                          where tgname = 'trg_block_duplicate_provider' and not tgisinternal)
            then '걸림' else '★ 없음' end as 상태;

select coalesce(left(profile_id::text, 8), '(계정 없음)') as 계정,
       count(*) as 살아있는_신청
  from public.providers
 where application_status in ('pending', 'approved') and profile_id is not null
 group by 1 having count(*) > 1 order by 2 desc;
