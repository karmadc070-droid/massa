-- 마사지사 명단에 '입금 기한' 과 '경고 보낸 날' 을 덧붙인다.
--
-- 왜 — 지표에서는 미납 금액만 보이고 '언제까지였는지' 를 알 수 없었다.
--      기한이 지났는지 모르면 언제 독촉해야 할지 판단이 안 선다.
--
-- 기한을 어떻게 잡나 — 가장 오래된 '미정산 완료 예약' 의 완료일 + due_days(기본 3일).
--   한 건씩 기한을 두면 관리가 안 된다. 가장 오래 기다린 건을 기준으로 한 줄만 본다.
--   미납이 0이면 기한도 없다 (null).
--
-- 경고는 자동으로 보내지 않는다 — warned_at 은 '사장님이 보낸 기록' 일 뿐이다.
--   사람에게 가는 독촉 알림을 코드가 멋대로 보내면 안 된다. 버튼은 사람이 누른다.

CREATE OR REPLACE FUNCTION public.admin_provider_list()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  cfg jsonb; res jsonb; win int; min_done int; min_rating numeric; due_days int;
begin
  if not exists (select 1 from profiles where id = auth.uid() and role = 'admin') then
    raise exception '관리자만 조회할 수 있습니다.' using errcode = '42501';
  end if;

  select value into cfg from app_settings where key = 'fee';
  win        := coalesce((cfg->'promote'->>'window_days')::int, 30);
  min_done   := coalesce((cfg->'promote'->>'min_done')::int, 20);
  min_rating := coalesce((cfg->'promote'->>'min_rating')::numeric, 4.7);
  -- 입금 유예일. 콘솔과 같은 설정을 본다 (두 화면이 다른 기한을 말하면 안 된다).
  due_days   := coalesce((cfg->>'due_days')::int, 3);

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
           pend.pending_cnt,
           -- 가장 오래된 미정산 완료 예약의 완료일 + 유예일. 미납이 없으면 null.
           case when greatest(coalesce(b.fee,0) - coalesce(dep.paid_fee,0)
                              - coalesce(cr.balance_vnd,0), 0) > 0
                then (od.first_done + (due_days || ' days')::interval) end as due_at,
           st.warned_at
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
    left join lateral (
      select min(coalesce(x.completed_at, x.created_at)) as first_done
        from bookings x
       where x.provider_id = pr.id and x.is_paid) od on true
    left join settlement st on st.provider_id = pr.id
    left join provider_credit cr on cr.provider_id = pr.id
    where pr.application_status in ('approved', 'pending')
  ) t;

  return res;
end $function$;
