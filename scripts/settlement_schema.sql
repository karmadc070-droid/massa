-- 수수료 입금 관리 스키마 — 제공자별 고유 입금코드, 입금 신고·확인, 선입금(페이백) 잔고.
-- 여러 번 실행해도 안전하다. 적용: scripts/vps-apply-settlement.sh

-- ── 1. 제공자 입금 고유코드 ─────────────────────────────────────
-- 현금 거래가 대부분이라 마사지사가 회사 계좌로 수수료를 이체한다.
-- 동명이인이 있으면 입금자명만으로 누가 냈는지 알 수 없어서, 짧은 코드를 발급해 이체 메모에 적게 한다.
alter table public.providers add column if not exists deposit_code text;

-- 코드가 없는 제공자에게 MS + 4자리를 채운다. 충돌하면 다시 뽑는다.
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

create unique index if not exists providers_deposit_code_key on public.providers (deposit_code);

-- ── 2. 입금 신고·확인 ──────────────────────────────────────────
-- 마사지사가 "입금했다"고 신고하면 reported, 관리자가 통장에서 확인하면 confirmed.
create table if not exists public.provider_deposit (
  id           uuid primary key default gen_random_uuid(),
  provider_id  uuid not null references public.providers(id) on delete cascade,
  cycle_id     uuid references public.settlement_cycle(id) on delete set null,
  kind         text not null default 'commission',   -- commission(수수료) | prepay(선입금)
  amount_vnd   bigint not null check (amount_vnd > 0),
  bonus_vnd    bigint not null default 0,            -- 선입금일 때만. 보너스 적립분
  status       text not null default 'reported',     -- reported | confirmed | rejected
  memo         text,                                  -- 이체 메모(입금자명)
  proof_url    text,
  reported_at  timestamptz not null default now(),
  confirmed_at timestamptz,
  confirmed_by uuid,
  reject_reason text,
  created_at   timestamptz not null default now()
);
create index if not exists provider_deposit_provider_idx on public.provider_deposit (provider_id, status);
create index if not exists provider_deposit_status_idx   on public.provider_deposit (status, reported_at desc);

-- ── 3. 선입금 잔고 (페이백) ────────────────────────────────────
-- 미리 넣어두면 수수료가 잔고에서 빠진다. 많이 넣을수록 보너스 적립률이 올라간다.
create table if not exists public.provider_credit (
  provider_id uuid primary key references public.providers(id) on delete cascade,
  balance_vnd bigint not null default 0,
  updated_at  timestamptz not null default now()
);

-- 잔고 증감 내역. balance_vnd 는 이 표의 합계와 항상 같아야 한다.
create table if not exists public.provider_credit_tx (
  id          uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.providers(id) on delete cascade,
  delta_vnd   bigint not null,                       -- + 충전·보너스, - 수수료 차감
  kind        text not null,                          -- prepay | bonus | commission | adjust
  ref_id      uuid,                                   -- provider_deposit.id 또는 bookings.id
  note        text,
  created_at  timestamptz not null default now()
);
create index if not exists provider_credit_tx_idx on public.provider_credit_tx (provider_id, created_at desc);

-- ── 4. RLS ────────────────────────────────────────────────────
alter table public.provider_deposit  enable row level security;
alter table public.provider_credit    enable row level security;
alter table public.provider_credit_tx enable row level security;

-- 본인이 소유한 제공자인지 판정. 프리랜서는 profile_id, 샵은 owner_id 로 연결된다.
create or replace function public.owns_provider(p uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.providers
    where id = p and (profile_id = auth.uid() or owner_id = auth.uid())
  );
$$;

drop policy if exists dep_select_own   on public.provider_deposit;
drop policy if exists dep_insert_own   on public.provider_deposit;
drop policy if exists dep_admin_all    on public.provider_deposit;
-- 제공자는 자기 것만 보고, 자기 것만 신고할 수 있다. 확인(confirmed)은 관리자만 한다.
create policy dep_select_own on public.provider_deposit for select
  using (public.owns_provider(provider_id) or public.is_admin());
create policy dep_insert_own on public.provider_deposit for insert
  with check (public.owns_provider(provider_id) and status = 'reported');
create policy dep_admin_all on public.provider_deposit for update
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists cred_select_own on public.provider_credit;
drop policy if exists cred_admin_all  on public.provider_credit;
create policy cred_select_own on public.provider_credit for select
  using (public.owns_provider(provider_id) or public.is_admin());
create policy cred_admin_all on public.provider_credit for all
  using (public.is_admin()) with check (public.is_admin());

drop policy if exists credtx_select_own on public.provider_credit_tx;
drop policy if exists credtx_admin_all  on public.provider_credit_tx;
create policy credtx_select_own on public.provider_credit_tx for select
  using (public.owns_provider(provider_id) or public.is_admin());
create policy credtx_admin_all on public.provider_credit_tx for all
  using (public.is_admin()) with check (public.is_admin());

-- ── 5. 입금 확인 RPC ──────────────────────────────────────────
-- 관리자가 통장에서 확인하고 승인한다. 선입금이면 보너스를 붙여 잔고에 넣는다.
create or replace function public.confirm_deposit(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
declare d record; v_total bigint;
begin
  if not public.is_admin() then
    raise exception '관리자만 확인할 수 있습니다.';
  end if;

  select * into d from public.provider_deposit where id = p_id for update;
  if d is null then raise exception '입금 내역이 없습니다.'; end if;
  if d.status = 'confirmed' then return; end if;   -- 두 번 눌러도 안전하게

  update public.provider_deposit
     set status = 'confirmed', confirmed_at = now(), confirmed_by = auth.uid()
   where id = p_id;

  if d.kind = 'prepay' then
    v_total := d.amount_vnd + coalesce(d.bonus_vnd, 0);
    insert into public.provider_credit (provider_id, balance_vnd, updated_at)
    values (d.provider_id, v_total, now())
    on conflict (provider_id) do update
      set balance_vnd = public.provider_credit.balance_vnd + v_total, updated_at = now();

    insert into public.provider_credit_tx (provider_id, delta_vnd, kind, ref_id, note)
    values (d.provider_id, d.amount_vnd, 'prepay', d.id, '선입금');
    if coalesce(d.bonus_vnd, 0) > 0 then
      insert into public.provider_credit_tx (provider_id, delta_vnd, kind, ref_id, note)
      values (d.provider_id, d.bonus_vnd, 'bonus', d.id, '선입금 보너스');
    end if;
  else
    -- 수수료 입금이면 해당 사이클을 입금 완료로 넘긴다
    if d.cycle_id is not null then
      update public.settlement_cycle set status = 'paid', paid_at = now() where id = d.cycle_id;
    end if;
    insert into public.settlement (provider_id, status, settled_at, updated_at)
    values (d.provider_id, 'paid', now(), now())
    on conflict (provider_id) do update
      set status = 'paid', settled_at = now(), updated_at = now();
  end if;
end $$;

-- ── 6. 선입금 구간 기본값 ──────────────────────────────────────
-- 금액은 임시값이다. 관리자 화면(수수료 관리)에서 바꿀 수 있다.
-- 90분 아로마 850,000₫ 기준 수수료가 건당 85,000₫ 이라, 월 20건이면 1.7M₫ 정도가 나온다.
insert into public.app_settings (key, value, updated_at)
values ('prepay', '{"enabled": false, "tiers": [
  {"min_vnd": 2000000,  "bonus": 0.10},
  {"min_vnd": 5000000,  "bonus": 0.15},
  {"min_vnd": 10000000, "bonus": 0.20}
]}'::jsonb, now())
on conflict (key) do nothing;

select 'settlement schema ok' as result;
