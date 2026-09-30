create table public.fuel_expenses (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null
    references public.vehicles(id) on delete cascade,
  liters numeric(10, 3) not null,
  cost_cents bigint not null,
  refueled_at timestamptz not null default now(),
  constraint fuel_expenses_liters_positive check (liters > 0),
  constraint fuel_expenses_cost_positive check (cost_cents > 0)
);

comment on table public.fuel_expenses is
  'Storico dei rifornimenti registrati dai proprietari dei veicoli.';
comment on column public.fuel_expenses.cost_cents is
  'Costo del rifornimento in centesimi di euro.';

create index fuel_expenses_vehicle_refueled_idx
  on public.fuel_expenses(vehicle_id, refueled_at);

alter table public.fuel_expenses enable row level security;

create policy fuel_expenses_owner_select
on public.fuel_expenses
for select
to authenticated
using (
  exists (
    select 1
    from public.vehicles v
    where v.id = fuel_expenses.vehicle_id
      and v.owner_id = (select auth.uid())
  )
);

create policy fuel_expenses_owner_insert
on public.fuel_expenses
for insert
to authenticated
with check (
  exists (
    select 1
    from public.vehicles v
    where v.id = fuel_expenses.vehicle_id
      and v.owner_id = (select auth.uid())
  )
);

create policy owner_registration_gate
on public.fuel_expenses
as restrictive
for all
to authenticated
using ((select private.owner_registration_ready()))
with check ((select private.owner_registration_ready()));

create trigger require_owner_registration
before insert or update on public.fuel_expenses
for each row execute function private.require_owner_registration();

revoke all on table public.fuel_expenses from public, anon, authenticated;
grant select, insert on table public.fuel_expenses to authenticated;

create or replace function public.aggiungi_rifornimento(
  p_vehicle_id uuid,
  p_liters_milli integer,
  p_cost_cents bigint
)
returns uuid
language plpgsql
volatile
security invoker
set search_path = ''
as $function$
declare
  inserted_id uuid;
begin
  if p_liters_milli <= 0 or p_cost_cents <= 0 then
    raise exception 'Costo e litri devono essere maggiori di zero'
      using errcode = '23514';
  end if;

  insert into public.fuel_expenses(vehicle_id, liters, cost_cents)
  values (p_vehicle_id, p_liters_milli::numeric / 1000, p_cost_cents)
  returning id into inserted_id;

  return inserted_id;
end;
$function$;

revoke all on function public.aggiungi_rifornimento(uuid, integer, bigint)
from public, anon;
grant execute on function public.aggiungi_rifornimento(uuid, integer, bigint)
to authenticated;

comment on function public.aggiungi_rifornimento(uuid, integer, bigint) is
  'Registra un rifornimento sul veicolo posseduto dall utente autenticato.';

create or replace view public.vista_veicoli_dashboard
with (security_invoker = true)
as
with ultimi_lavori as (
  select distinct on (mr.vehicle_id, mi.type)
    mr.vehicle_id,
    mi.type,
    mi.service_km,
    mi.service_date
  from public.maintenance_items mi
  join public.maintenance_records mr on mr.id = mi.record_id
  order by mr.vehicle_id, mi.type, mi.service_km desc
), costi_per_anno as (
  select
    mr.vehicle_id,
    extract(year from mi.service_date)::integer as maintenance_year,
    round(sum(mip.quantity * mip.unit_price) * 100)::bigint as cost_cents,
    min(mi.service_date) as first_maintenance_date
  from public.maintenance_records mr
  join public.maintenance_items mi on mi.record_id = mr.id
  join public.maintenance_item_parts mip on mip.item_id = mi.id
  where mip.unit_price is not null
  group by mr.vehicle_id, extract(year from mi.service_date)
), costi_manutenzione as (
  select
    vehicle_id,
    sum(cost_cents)::bigint as maintenance_cost_cents,
    min(first_maintenance_date) as first_maintenance_date,
    jsonb_object_agg(maintenance_year::text, cost_cents order by maintenance_year)
      as maintenance_costs_by_year
  from costi_per_anno
  group by vehicle_id
), costi_carburante as (
  select
    vehicle_id,
    sum(cost_cents)::numeric as total_cost_cents,
    greatest(
      (now() at time zone 'Europe/Rome')::date
        - min((refueled_at at time zone 'Europe/Rome')::date) + 1,
      1
    )::numeric as observed_days
  from public.fuel_expenses
  group by vehicle_id
), medie_carburante as (
  select
    vehicle_id,
    round(total_cost_cents / observed_days)::bigint
      as fuel_daily_cost_cents,
    round(total_cost_cents / observed_days * 365.2425 / 12)::bigint
      as fuel_monthly_cost_cents,
    round(total_cost_cents / observed_days * 365.2425)::bigint
      as fuel_annual_cost_cents
  from costi_carburante
)
select
  v.id,
  v.owner_id,
  v.plate,
  v.brand,
  v.model,
  v.year,
  v.fuel,
  v.power_cv,
  v.displacement_cc,
  v.km_current,
  v.scadenza_revision_date,
  v.tagliando_interval_km,
  v.tire_change_interval_km,
  v.tire_rotation_interval_km,
  v.created_at,
  v.updated_at,
  v.distribution_intervall_km,
  max(u.service_km) filter (where u.type = 'tagliando') as last_tagliando_km,
  max(u.service_date) filter (where u.type = 'tagliando') as last_tagliando_date,
  max(u.service_km) filter (where u.type = 'distribuzione') as last_distribuzione_km,
  max(u.service_date) filter (where u.type = 'distribuzione') as last_distribuzione_date,
  max(u.service_km) filter (where u.type = 'pneumatici_cambio') as last_tire_change_km,
  max(u.service_date) filter (where u.type = 'pneumatici_cambio') as last_tire_change_date,
  max(u.service_km) filter (where u.type = 'pneumatici_inversione') as last_tire_rotation_km,
  max(u.service_date) filter (where u.type = 'pneumatici_inversione') as last_tire_rotation_date,
  max(u.service_date) filter (where u.type = 'revisione') as last_revision_date,
  coalesce(
    (select max(vh.created_at) from public.vehicle_history vh where vh.vehicle_id = v.id),
    v.created_at
  ) as km_updated_at,
  coalesce(c.maintenance_cost_cents, 0) as maintenance_cost_cents,
  c.first_maintenance_date,
  coalesce(c.maintenance_costs_by_year, '{}'::jsonb)
    as maintenance_costs_by_year,
  coalesce(f.fuel_daily_cost_cents, 0) as fuel_daily_cost_cents,
  coalesce(f.fuel_monthly_cost_cents, 0) as fuel_monthly_cost_cents,
  coalesce(f.fuel_annual_cost_cents, 0) as fuel_annual_cost_cents
from public.vehicles v
left join ultimi_lavori u on u.vehicle_id = v.id
left join costi_manutenzione c on c.vehicle_id = v.id
left join medie_carburante f on f.vehicle_id = v.id
group by
  v.id,
  c.maintenance_cost_cents,
  c.first_maintenance_date,
  c.maintenance_costs_by_year,
  f.fuel_daily_cost_cents,
  f.fuel_monthly_cost_cents,
  f.fuel_annual_cost_cents;
