insert into public.parts (id, name, category)
overriding system value
values
  (200, 'Olio motore', 'motore'),
  (201, 'Olio cambio', 'cambio'),
  (202, 'Olio differenziale', 'cambio'),
  (203, 'Filtro GPL/metano', 'veicolo'),
  (204, 'Serbatoio GPL', 'veicolo'),
  (205, 'Bombole metano', 'veicolo'),
  (206, 'Kit distribuzione e cuscinetti', 'motore');

alter table public.vehicles add column brake_inspection_date date;

create table public.vehicle_component_maintenance (
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  part_id bigint not null references public.parts(id),
  work_type text not null check (work_type in (
    'tagliando', 'freni', 'motore', 'cambio', 'distribuzione', 'pneumatici_cambio', 'altro'
  )),
  interval_km integer check (
    interval_km between 1000 and 150000 and
    interval_km % (case when interval_km <= 60000 then 1000 else 5000 end) = 0
  ),
  interval_years integer check (interval_years between 1 and 20),
  initial_km integer check (initial_km >= 0),
  initial_date date,
  primary key (vehicle_id, part_id),
  check (interval_km is not null or interval_years is not null)
);

alter table public.vehicle_component_maintenance enable row level security;
grant select, insert on public.vehicle_component_maintenance to authenticated;

create policy vehicle_component_maintenance_select
  on public.vehicle_component_maintenance for select to authenticated
  using (exists (
    select from public.vehicles v
    where v.id = vehicle_component_maintenance.vehicle_id
  ));

create policy vehicle_component_maintenance_insert
  on public.vehicle_component_maintenance for insert to authenticated
  with check (exists (
    select from public.vehicles v
    where v.id = vehicle_component_maintenance.vehicle_id
      and v.owner_id = (select auth.uid())
      and (initial_km is null or initial_km <= v.km_current)
  ));

create function public.crea_veicolo_con_manutenzione_componenti(p_payload jsonb)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  registered_vehicle_id uuid;
begin
  registered_vehicle_id := public.crea_veicolo_con_storico(p_payload);

  insert into public.vehicle_component_maintenance (
    vehicle_id, part_id, work_type, interval_km, interval_years, initial_km, initial_date
  )
  select registered_vehicle_id, component.part_id, component.work_type, component.interval_km,
    component.interval_years, component.initial_km, component.initial_date
  from jsonb_to_recordset(p_payload -> 'maintenance_components') as component(
    part_id bigint, work_type text, interval_km integer, interval_years integer,
    initial_km integer, initial_date date
  );

  if p_payload ->> 'brake_inspection_date' is not null then
    update public.vehicles
    set brake_inspection_date = (p_payload ->> 'brake_inspection_date')::date
    where id = registered_vehicle_id;
  end if;

  return registered_vehicle_id;
end;
$$;
revoke all on function public.crea_veicolo_con_manutenzione_componenti(jsonb) from public, anon;
grant execute on function public.crea_veicolo_con_manutenzione_componenti(jsonb) to authenticated;

create function public.vehicle_component_maintenance_status(p_vehicle_ids uuid[])
returns table (
  vehicle_id uuid, part_id bigint, interval_km integer, interval_years integer,
  last_service_km integer, last_service_date date, brake_inspection_date date
)
language sql
stable
security invoker
set search_path = ''
as $$
  with configured as materialized (
    select c.* from public.vehicle_component_maintenance c
    where c.vehicle_id = any (p_vehicle_ids)
  ), latest as (
    select distinct on (c.vehicle_id, c.part_id)
      c.vehicle_id, c.part_id, i.service_km, i.service_date
    from public.maintenance_records r
    join public.maintenance_items i on i.record_id = r.id
    join public.maintenance_item_parts p on p.item_id = i.id
    join configured c on c.vehicle_id = r.vehicle_id and c.part_id = p.part_id
    where r.vehicle_id = any (p_vehicle_ids)
      and case
        when c.initial_date is not null then i.service_date >= c.initial_date
        when c.initial_km is not null then i.service_km >= c.initial_km
        else true
      end
    order by c.vehicle_id, c.part_id, i.service_date desc nulls last,
      i.service_km desc nulls last, i.id desc
  )
  select c.vehicle_id, c.part_id, c.interval_km, c.interval_years,
    case when l.part_id is null then c.initial_km else l.service_km end,
    case when l.part_id is null then c.initial_date else l.service_date end,
    v.brake_inspection_date
  from configured c
  join public.vehicles v on v.id = c.vehicle_id
  left join latest l on l.vehicle_id = c.vehicle_id and l.part_id = c.part_id;
$$;
revoke all on function public.vehicle_component_maintenance_status(uuid[]) from public, anon;
grant execute on function public.vehicle_component_maintenance_status(uuid[]) to authenticated;

notify pgrst, 'reload schema';
