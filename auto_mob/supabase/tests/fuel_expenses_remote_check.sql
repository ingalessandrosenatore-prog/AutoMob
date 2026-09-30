begin;

do $check$
declare
  target_vehicle_id uuid;
  target_owner_id uuid;
  inserted_id uuid;
  daily_cost bigint;
  monthly_cost bigint;
  annual_cost bigint;
begin
  select v.id, v.owner_id
  into target_vehicle_id, target_owner_id
  from public.vehicles v
  join public.profiles p on p.id = v.owner_id
  where coalesce(p.owner_onboarding_required, false) = false
  limit 1;

  if target_vehicle_id is null then
    raise exception 'Nessun veicolo owner disponibile per il test';
  end if;

  perform set_config('request.jwt.claim.sub', target_owner_id::text, true);
  perform set_config(
    'request.jwt.claims',
    json_build_object('sub', target_owner_id, 'role', 'authenticated')::text,
    true
  );
  execute 'set local role authenticated';

  inserted_id := public.aggiungi_rifornimento(
    target_vehicle_id,
    32750,
    5025
  );

  select
    fuel_daily_cost_cents,
    fuel_monthly_cost_cents,
    fuel_annual_cost_cents
  into daily_cost, monthly_cost, annual_cost
  from public.vista_veicoli_dashboard
  where id = target_vehicle_id;

  if inserted_id is null
    or daily_cost <> 14
    or monthly_cost <> 419
    or annual_cost <> 5025 then
    raise exception 'RPC o KPI carburante non validi';
  end if;
end;
$check$;

rollback;
