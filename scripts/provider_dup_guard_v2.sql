-- 마사지사 중복 등록 신청을 막는다 (2026-10-04, v2).
--
-- v1 이 왜 안 먹었나:
--   trg_block_duplicate_provider 가 profile_id 만 본다. 그런데 첫 줄이
--   `if new.profile_id is null then return new; end if;` 다.
--   실제 등록자는 대부분 owner_id 로 붙고 profile_id 는 비어 있다 →
--   트리거가 아무것도 안 하고 그냥 통과시켰다. Thanh hà 가 4건 들어온 경로다.
--
-- v2 에서 바꾸는 것:
--   1) owner_id 도 같이 본다 (실제로 쓰이는 쪽)
--   2) UPDATE 도 막는다. 반려된 행을 pending 으로 되돌려 우회하는 걸 차단
--
-- 유니크 인덱스는 **지금 걸 수 없다.** 시드 마사지사 8명(Hoai T., Linh N. 등 7월 7일 생성)이
-- 전부 한 계정(adec3c30)의 owner_id 로 묶여 있어서 인덱스 생성이 실패한다.
-- 시드 정리(#53)가 끝나면 아래 두 줄을 풀어서 걸 것. 그게 동시 요청까지 막는 마지막 방어선이다.
--   create unique index providers_one_live_per_owner   on providers (owner_id)
--     where owner_id   is not null and application_status in ('pending','approved');
--   create unique index providers_one_live_per_profile on providers (profile_id)
--     where profile_id is not null and application_status in ('pending','approved');
-- 트리거만으로는 같은 순간에 들어온 두 요청이 둘 다 통과할 수 있다. 다만 사람이 버튼을
-- 누르는 간격(Thanh hà 는 4초·24초)에서는 트리거가 잡는다.
--
-- 전화번호로는 막지 않는다. 매장(shop) 하나에 여러 명을 등록하는 경우가 정상이라
-- 멀쩡한 신청까지 막게 된다. 중복 전화는 운영 화면에서 눈으로 본다.

begin;

create or replace function public.block_duplicate_provider()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare n int;
begin
  -- 살아 있는 상태가 아니면 볼 것 없다 (반려·보류 등)
  if new.application_status not in ('pending', 'approved') then
    return new;
  end if;

  -- UPDATE 는 '중복을 새로 만드는' 경우에만 본다.
  -- 이걸 안 하면 이미 같은 owner 로 묶여 있는 시드 8명을 운영 화면에서 손댈 때마다 터진다.
  -- 승인·가격수정 같은 평범한 수정은 그냥 통과해야 한다.
  if tg_op = 'UPDATE'
     and new.owner_id   is not distinct from old.owner_id
     and new.profile_id is not distinct from old.profile_id
     and old.application_status in ('pending', 'approved') then
    return new;
  end if;

  -- 같은 사람(owner_id 또는 profile_id)이 이미 살아 있는 신청을 갖고 있나
  select count(*) into n
  from public.providers
  where application_status in ('pending', 'approved')
    and id <> coalesce(new.id, '00000000-0000-0000-0000-000000000000'::uuid)
    and (
      (new.owner_id   is not null and owner_id   = new.owner_id) or
      (new.profile_id is not null and profile_id = new.profile_id)
    );

  if n > 0 then
    raise exception '이미 등록 신청이 있습니다. 심사 결과를 기다려 주세요.'
      using errcode = '23505';
  end if;
  return new;
end $function$;

drop trigger if exists trg_block_duplicate_provider on public.providers;
create trigger trg_block_duplicate_provider
  before insert or update on public.providers
  for each row execute function public.block_duplicate_provider();

commit;
