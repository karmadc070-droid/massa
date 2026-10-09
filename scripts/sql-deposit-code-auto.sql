-- 신규 마사지사에게 입금코드(MS####)를 자동 발급하고, 코드 없는 기존 사람을 채운다.
--
-- 왜 필요한가 - settlement_schema.sql 의 코드 채우기는 '그 스크립트를 돌린 그 순간' 한 번만 돌았다.
--               그 뒤에 가입한 사람은 코드가 없고, 운영 화면에 '코드 없음' 으로 뜬다.
--               수수료 이체 메모에 적을 식별자가 없으니 누가 냈는지 가릴 수 없다.
--
-- 트리거 이름 - providers 의 BEFORE 트리거는 이름순으로 돈다.
--               guard_provider_write() 가 '신청 시 deposit_code 가 null 이 아니면 거부' 하므로
--               발급은 반드시 trg_provider_guard 보다 **뒤에** 돌아야 한다. 그래서 zz_ 를 붙였다.

create or replace function public.assign_deposit_code()
returns trigger
language plpgsql
set search_path to 'public'
as $$
declare c text; n int; tries int := 0;
begin
  if new.deposit_code is not null then
    return new;
  end if;

  loop
    tries := tries + 1;
    c := 'MS' || lpad((floor(random() * 10000))::int::text, 4, '0');
    select count(*) into n from public.providers where deposit_code = c;
    exit when n = 0;
    if tries > 50 then
      raise exception '빈 입금코드를 50번 뽑아도 못 찾았습니다. 자리수를 늘려야 합니다.';
    end if;
  end loop;

  new.deposit_code := c;
  return new;
end $$;

drop trigger if exists trg_provider_zz_code on public.providers;
create trigger trg_provider_zz_code
  before insert on public.providers
  for each row execute function public.assign_deposit_code();

-- 이미 가입했는데 코드가 없는 사람을 채운다. 트리거와 같은 방식이다.
do $$
declare r record; c text; n int;
begin
  for r in select id from public.providers where deposit_code is null loop
    loop
      c := 'MS' || lpad((floor(random() * 10000))::int::text, 4, '0');
      select count(*) into n from public.providers where deposit_code = c;
      exit when n = 0;
    end loop;
    update public.providers set deposit_code = c where id = r.id;
  end loop;
end $$;

comment on function public.assign_deposit_code() is
  '신규 providers 행에 MS#### 입금코드를 발급한다. trg_provider_guard 보다 뒤에 돌아야 한다.';
