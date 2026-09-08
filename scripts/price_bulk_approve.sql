-- 승인 대기 가격을 골라서 한 번에 승인한다.
--
-- 한 건이 범위를 벗어나도 나머지는 승인한다. 전부 되돌리면 관리자가 어느 게 문제인지 모른 채
-- 다시 처음부터 골라야 한다. 대신 실패한 건은 이유와 함께 돌려준다.
-- 검사는 admin_review_price 와 똑같이 한다 (한 곳에서만 판단하도록 그 함수를 그대로 부른다).

create or replace function public.admin_approve_prices(p_items jsonb)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  it     jsonb;
  ok_n   int := 0;
  fails  jsonb := '[]'::jsonb;
  pv     uuid;
  sv     uuid;
begin
  if not public.is_admin() then raise exception '관리자만 처리할 수 있습니다.'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' then
    raise exception '승인할 항목을 고르지 않았습니다.';
  end if;

  for it in select * from jsonb_array_elements(p_items) loop
    pv := (it->>'provider_id')::uuid;
    sv := (it->>'service_id')::uuid;
    begin
      perform public.admin_review_price(pv, sv, true, null);
      ok_n := ok_n + 1;
    exception when others then
      -- 어느 건이 왜 막혔는지 화면에 그대로 보여 준다
      fails := fails || jsonb_build_object(
        'provider_name', (select display_name from public.providers where id = pv),
        'service_name',  (select name         from public.services  where id = sv),
        'reason',        SQLERRM);
    end;
  end loop;

  return jsonb_build_object('ok', ok_n, 'fails', fails);
end $$;

-- ── 확인 ─────────────────────────────────────────────────────
select case when exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                          where n.nspname='public' and p.proname='admin_approve_prices')
            then '함수 admin_approve_prices 있음' else '★ 없음' end as 확인;
