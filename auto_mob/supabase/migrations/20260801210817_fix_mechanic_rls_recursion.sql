-- Le policy originarie di vehicle_mechanics e vehicles si interrogavano a
-- vicenda. Queste funzioni ristrette spezzano il ciclo mantenendo auth.uid()
-- come unica fonte dell'identita corrente.

create or replace function public.is_vehicle_owned_by_current_user(target_vehicle_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.vehicles v
    where v.id = target_vehicle_id
      and v.owner_id = auth.uid()
  );
$$;

create or replace function public.is_vehicle_assigned_to_current_mechanic(target_vehicle_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.vehicle_mechanics vm
    join public.mechanics m on m.id = vm.mechanic_id
    where vm.vehicle_id = target_vehicle_id
      and m.user_id = auth.uid()
      and m.is_active = true
  );
$$;

create or replace function public.is_record_assigned_to_current_mechanic(target_record_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.maintenance_records mr
    join public.vehicle_mechanics vm on vm.vehicle_id = mr.vehicle_id
    join public.mechanics m on m.id = vm.mechanic_id
    where mr.id = target_record_id
      and m.user_id = auth.uid()
      and m.is_active = true
  );
$$;

revoke all on function public.is_vehicle_owned_by_current_user(uuid) from public;
revoke all on function public.is_vehicle_owned_by_current_user(uuid) from anon;
grant execute on function public.is_vehicle_owned_by_current_user(uuid) to authenticated;

revoke all on function public.is_vehicle_assigned_to_current_mechanic(uuid) from public;
revoke all on function public.is_vehicle_assigned_to_current_mechanic(uuid) from anon;
grant execute on function public.is_vehicle_assigned_to_current_mechanic(uuid) to authenticated;

revoke all on function public.is_record_assigned_to_current_mechanic(uuid) from public;
revoke all on function public.is_record_assigned_to_current_mechanic(uuid) from anon;
grant execute on function public.is_record_assigned_to_current_mechanic(uuid) to authenticated;

drop policy if exists vm_select_owner on public.vehicle_mechanics;
create policy vm_select_owner
on public.vehicle_mechanics
for select
to authenticated
using (public.is_vehicle_owned_by_current_user(vehicle_id));

drop policy if exists vehicles_select_assigned_mechanic on public.vehicles;
create policy vehicles_select_assigned_mechanic
on public.vehicles
for select
to authenticated
using (public.is_vehicle_assigned_to_current_mechanic(id));

drop policy if exists records_select_assigned_mechanic on public.maintenance_records;
create policy records_select_assigned_mechanic
on public.maintenance_records
for select
to authenticated
using (public.is_vehicle_assigned_to_current_mechanic(vehicle_id));

drop policy if exists items_select_assigned_mechanic on public.maintenance_items;
create policy items_select_assigned_mechanic
on public.maintenance_items
for select
to authenticated
using (public.is_record_assigned_to_current_mechanic(record_id));
