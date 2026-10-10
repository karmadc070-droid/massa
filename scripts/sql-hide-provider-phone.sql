-- 마사지사 전화번호가 로그인 없이 전부 보이던 것을 막는다.
--
-- 무슨 일이었나 — providers 는 고객 목록을 그려야 해서 anon 에게 열려 있다.
--   그런데 열려 있는 건 '행' 이 아니라 '칸 전부' 였다. phone 도 같이 나갔다.
--   앱 코드에는 "연락처는 직거래를 막으려고 관리자에게만 보인다"(index.html 1645행)고
--   적혀 있는데, 화면만 가렸을 뿐 API 는 누구에게나 내주고 있었다. 화면 통제는 통제가 아니다.
--
-- 왜 칸 권한(column grant)으로 안 막았나 — 고객 앱이 `select('*')` 로 부른다
--   (index.html 4173행). 칸 하나라도 revoke 하면 `*` 가 통째로 403 이 되어 앱이 죽는다.
--   칸 권한은 앱이 칸을 하나씩 적게 고친 뒤에 할 일이다.
--
-- 그래서 — 값을 아예 두지 않는다. 같은 번호가 provider_kyc.contact 에 이미 있고
--   그 테이블은 관리자만 읽는다 (anon 으로 조회 시 0행). 지워도 잃는 정보가 없다.
--   5명 전부 두 곳의 값이 같은 것을 확인하고 지운다.

begin;

-- 1) 안전 확인 — kyc 에 번호가 없는 사람이 있으면 중단한다. 지우면 연락할 길이 없어진다.
do $$
declare n int;
begin
  select count(*) into n
    from providers p
    left join provider_kyc k on k.provider_id = p.id
   where p.phone is not null
     and (k.contact is null or k.contact <> p.phone);
  if n > 0 then
    raise exception 'kyc 에 번호가 없거나 다른 사람이 %명 있다 - 중단한다. 먼저 옮길 것', n;
  end if;
end $$;

-- 2) 지금 들어 있는 값을 비운다
update providers set phone = null where phone is not null;

-- 3) 앞으로도 들어오지 않게 막는다.
--    앱은 신청할 때 연락처를 providers.phone 과 provider_kyc.contact 양쪽에 쓴다
--    (index.html 2914행·2931행). 앱을 고쳐 배포해도 옛 버전을 쓰는 사람이 남는다.
--    그래서 DB 에서 막는다. 여기서 막으면 어떤 버전이 들어와도 새지 않는다.
create or replace function public.strip_provider_phone()
returns trigger
language plpgsql
set search_path to 'public'
as $$
begin
  new.phone := null;   -- 연락처의 정본은 provider_kyc.contact 다
  return new;
end $$;

-- providers 의 BEFORE 트리거는 이름순으로 돈다.
-- guard_provider_write 가 먼저 검사하고, 그 뒤에 비운다 (입금코드 트리거와 같은 이유).
drop trigger if exists trg_provider_zz_phone on public.providers;
create trigger trg_provider_zz_phone
  before insert or update on public.providers
  for each row execute function public.strip_provider_phone();

commit;

comment on function public.strip_provider_phone() is
  'providers.phone 을 항상 비운다. 연락처 정본은 provider_kyc.contact (관리자 전용).';
