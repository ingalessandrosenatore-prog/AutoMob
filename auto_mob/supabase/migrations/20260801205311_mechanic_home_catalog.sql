-- Consente al meccanico autenticato di leggere esclusivamente i veicoli
-- collegati alla propria officina e i dati minimi necessari per calcolare
-- lo stato manutentivo lato dominio Flutter.

drop policy if exists vehicles_select_assigned_mechanic on public.vehicles;
create policy vehicles_select_assigned_mechanic
on public.vehicles
for select
to authenticated
using (
  exists (
    select 1
    from public.vehicle_mechanics vm
    join public.mechanics m on m.id = vm.mechanic_id
    where vm.vehicle_id = vehicles.id
      and m.user_id = (select auth.uid())
      and m.is_active = true
  )
);

drop policy if exists items_select_assigned_mechanic on public.maintenance_items;
create policy items_select_assigned_mechanic
on public.maintenance_items
for select
to authenticated
using (
  exists (
    select 1
    from public.maintenance_records mr
    join public.vehicle_mechanics vm on vm.vehicle_id = mr.vehicle_id
    join public.mechanics m on m.id = vm.mechanic_id
    where mr.id = maintenance_items.record_id
      and m.user_id = (select auth.uid())
      and m.is_active = true
  )
);

create or replace function public.get_mechanic_home_catalog()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with session_context as (
    select
      m.id as mechanic_id,
      coalesce(nullif(trim(p.full_name), ''), nullif(trim(m.business_name), ''), 'Meccanico')
        as display_name,
      m.business_name,
      m.mechanic_code
    from (select auth.uid() as user_id) session
    left join public.profiles p on p.id = session.user_id
    left join public.mechanics m
      on m.user_id = session.user_id
      and m.is_active = true
  ),
  linked_vehicles as (
    select distinct
      v.id,
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
      v.distribution_intervall_km,
      v.tire_change_interval_km,
      v.tire_rotation_interval_km,
      v.created_at,
      v.updated_at
    from session_context sc
    join public.vehicle_mechanics vm on vm.mechanic_id = sc.mechanic_id
    join public.vehicles v on v.id = vm.vehicle_id
  ),
  last_service_km as (
    select
      mr.vehicle_id,
      max(mi.service_km) filter (where mi.type = 'tagliando') as last_tagliando_km,
      max(mi.service_km) filter (where mi.type = 'distribuzione') as last_distribuzione_km
    from public.maintenance_records mr
    join public.maintenance_items mi on mi.record_id = mr.id
    join linked_vehicles lv on lv.id = mr.vehicle_id
    group by mr.vehicle_id
  ),
  catalog as (
    select jsonb_agg(
      jsonb_build_object(
        'id', lv.id,
        'plate', lv.plate,
        'brand', lv.brand,
        'model', lv.model,
        'year', lv.year,
        'fuel', lv.fuel,
        'power_cv', lv.power_cv,
        'displacement_cc', lv.displacement_cc,
        'km_current', lv.km_current,
        'scadenza_revision_date', lv.scadenza_revision_date,
        'tagliando_interval_km', lv.tagliando_interval_km,
        'distribution_intervall_km', lv.distribution_intervall_km,
        'tire_change_interval_km', lv.tire_change_interval_km,
        'tire_rotation_interval_km', lv.tire_rotation_interval_km,
        'last_tagliando_km', lsk.last_tagliando_km,
        'last_distribuzione_km', lsk.last_distribuzione_km,
        'created_at', lv.created_at,
        'updated_at', lv.updated_at
      ) order by lower(lv.brand), lower(lv.model), lower(lv.plate)
    ) as vehicles
    from linked_vehicles lv
    left join last_service_km lsk on lsk.vehicle_id = lv.id
  )
  select jsonb_build_object(
    'mechanic', jsonb_build_object(
      'display_name', sc.display_name,
      'business_name', sc.business_name,
      'mechanic_code', sc.mechanic_code
    ),
    'total', coalesce(jsonb_array_length(catalog.vehicles), 0),
    'vehicles', coalesce(catalog.vehicles, '[]'::jsonb)
  )
  from session_context sc
  cross join catalog;
$$;

revoke all on function public.get_mechanic_home_catalog() from public;
revoke all on function public.get_mechanic_home_catalog() from anon;
grant execute on function public.get_mechanic_home_catalog() to authenticated;

comment on function public.get_mechanic_home_catalog() is
  'Catalogo completo dei veicoli collegati al meccanico autenticato, senza lavori o dati proprietario.';
