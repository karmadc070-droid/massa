-- 오픈 기념 일괄 10% + 마사지사 전체 명단(미납 수수료·선입금 잔액) + 관리자 수동 페이백.
-- 3단계 기준(10·15·20%)은 그대로 두고, 지금은 전원 우대 등급으로 맞춘다.

-- ── 1. 오픈 기념: 전원 10% ───────────────────────────────────
update public.providers
   set fee_tier = 'vip', fee_tier_at = now()
 where fee_tier <> 'vip';

-- 앞으로 새로 승인되는 사람도 오픈 기간에는 10% 로 들어오게 기본값을 바꾼다.
-- 오픈 행사가 끝나면 이 기본값을 'freelancer' 로 되돌리면 된다.
alter table public.providers alter column fee_tier set default 'vip';

-- ── 2. 마사지사 전체 명단 ────────────────────────────────────
-- 미납 = 발생한 수수료 − 확인된 수수료 입금 − 선입금 잔액. 음수면 0으로 본다.
create or replace function public.admin_provider_list()
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  cfg jsonb; res jsonb; win int; min_done int; min_rating numeric;
begin
  if not exists (select 1 from profiles where id = auth.uid() and role = 'admin') then
    raise exception '관리자만 조회할 수 있습니다.' using errcode = '42501';
  end if;

  select value into cfg from app_settings where key = 'fee';
  win        := coalesce((cfg->'promote'->>'window_days')::int, 30);
  min_done   := coalesce((cfg->'promote'->>'min_done')::int, 20);
  min_rating := coalesce((cfg->'promote'->>'min_rating')::numeric, 4.7);

  select jsonb_build_object(
    'tiers',   cfg->'tiers',
    'promote', cfg->'promote',
    'prepay',  (select value from app_settings where key = 'prepay'),
    'rows',    coalesce(jsonb_agg(t order by t.owe desc, t.done_recent desc, t.name), '[]'::jsonb)
  ) into res
  from (
    select pr.id, pr.display_name as name, pr.photo_url,
           pr.fee_tier::text as tier,
           (cfg->'tiers'->>pr.fee_tier::text)::numeric as rate,
           pr.rating, pr.review_count, pr.base_district as district,
           pr.deposit_code, pr.is_active, pr.application_status::text as status,
           pr.created_at::date::text as joined,
           b.cnt, b.gross, b.fee,
           dep.paid_fee,
           coalesce(cr.balance_vnd, 0) as credit,
           greatest(coalesce(b.fee,0) - coalesce(dep.paid_fee,0) - coalesce(cr.balance_vnd,0), 0) as owe,
           rc.done_recent,
           (rc.done_recent >= min_done and coalesce(pr.rating,0) >= min_rating
            and pr.fee_tier <> 'vip') as suggest_vip,
           pend.pending_cnt
    from providers pr
    left join lateral (
      select count(*)::int as cnt,
             coalesce(sum(x.amount_vnd),0)::bigint as gross,
             coalesce(sum(round(x.amount_vnd * coalesce(x.fee_rate, 0.20))),0)::bigint as fee
        from bookings x where x.provider_id = pr.id and x.is_paid) b on true
    left join lateral (
      select coalesce(sum(d.amount_vnd),0)::bigint as paid_fee
        from provider_deposit d
       where d.provider_id = pr.id and d.kind = 'commission' and d.status = 'confirmed') dep on true
    left join lateral (
      select count(*)::int as pending_cnt from provider_deposit d
       where d.provider_id = pr.id and d.status = 'reported') pend on true
    left join lateral (
      select count(*)::int as done_recent from bookings x
       where x.provider_id = pr.id and x.status = 'completed'
         and x.completed_at >= now() - (win || ' days')::interval) rc on true
    left join provider_credit cr on cr.provider_id = pr.id
    where pr.application_status in ('approved', 'pending')
  ) t;

  return res;
end $$;

-- ── 3. 관리자가 직접 넣는 페이백(선입금) ─────────────────────
-- 통장에서 확인한 뒤 넣는 것이므로 신고 단계를 거치지 않고 바로 확정한다.
-- 보너스를 비워 두면 app_settings.prepay 의 구간에서 자동으로 계산한다.
create or replace function public.admin_add_prepay(
  p_provider uuid, p_amount bigint, p_bonus bigint default null, p_memo text default null)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v_bonus bigint; v_rate numeric; v_id uuid;
begin
  if not exists (select 1 from profiles where id = auth.uid() and role = 'admin') then
    raise exception '관리자만 등록할 수 있습니다.' using errcode = '42501';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception '금액은 0보다 커야 합니다.';
  end if;
  if not exists (select 1 from providers where id = p_provider) then
    raise exception '해당 마사지사를 찾을 수 없습니다.';
  end if;

  if p_bonus is null then
    -- 넣은 금액이 넘어서는 가장 높은 구간의 보너스를 적용한다
    select max((e->>'bonus')::numeric) into v_rate
      from app_settings s, jsonb_array_elements(s.value->'tiers') e
     where s.key = 'prepay' and p_amount >= (e->>'min_vnd')::bigint;
    v_bonus := round(p_amount * coalesce(v_rate, 0));
  else
    v_bonus := greatest(p_bonus, 0);
  end if;

  insert into public.provider_deposit
    (provider_id, kind, amount_vnd, bonus_vnd, status, memo, reported_at)
  values (p_provider, 'prepay', p_amount, v_bonus, 'reported',
          coalesce(p_memo, '관리자 직접 입력'), now())
  returning id into v_id;

  perform public.confirm_deposit(v_id);   -- 잔고 적립까지 한 번에

  return jsonb_build_object(
    'id', v_id, 'amount', p_amount, 'bonus', v_bonus,
    'balance', (select balance_vnd from provider_credit where provider_id = p_provider));
end $$;

-- ── 4. 선입금 잔고에서 수수료를 차감한다 ─────────────────────
-- 자동으로 깎지 않는다. 관리자가 "이번 건 잔고에서 빼겠다" 고 누를 때만 움직인다.
create or replace function public.admin_use_credit(
  p_provider uuid, p_amount bigint, p_memo text default null)
returns jsonb
language plpgsql security definer set search_path = public as $$
declare v_bal bigint;
begin
  if not exists (select 1 from profiles where id = auth.uid() and role = 'admin') then
    raise exception '관리자만 차감할 수 있습니다.' using errcode = '42501';
  end if;
  select balance_vnd into v_bal from provider_credit where provider_id = p_provider for update;
  if coalesce(v_bal, 0) < p_amount then
    raise exception '잔고가 모자랍니다. 현재 잔고 %', coalesce(v_bal, 0);
  end if;

  update provider_credit set balance_vnd = balance_vnd - p_amount, updated_at = now()
   where provider_id = p_provider;
  insert into provider_credit_tx (provider_id, delta_vnd, kind, note)
  values (p_provider, -p_amount, 'commission', coalesce(p_memo, '수수료 차감'));

  return jsonb_build_object('balance',
    (select balance_vnd from provider_credit where provider_id = p_provider));
end $$;

revoke execute on function public.admin_provider_list()                       from anon;
revoke execute on function public.admin_add_prepay(uuid, bigint, bigint, text) from anon;
revoke execute on function public.admin_use_credit(uuid, bigint, text)         from anon;
grant  execute on function public.admin_provider_list()                        to authenticated;
grant  execute on function public.admin_add_prepay(uuid, bigint, bigint, text) to authenticated;
grant  execute on function public.admin_use_credit(uuid, bigint, text)         to authenticated;
