create table public.future_work_records (
  id uuid primary key default gen_random_uuid(),
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  created_by_user_id uuid not null references auth.users(id) on delete cascade,
  mechanic_id uuid references public.mechanics(id) on delete set null,
  done boolean not null default false,
  created_at timestamptz not null default now()
);

create table public.future_work_items (
  id uuid primary key default gen_random_uuid(),
  record_id uuid not null references public.future_work_records(id)
    on delete cascade,
  description text not null
    check (length(btrim(description)) between 1 and 1000),
  created_at timestamptz not null default now()
);

comment on table public.future_work_records is
  'Gruppi di lavori futuri o problemi segnalati per un veicolo.';
comment on column public.future_work_records.created_by_user_id is
  'Utente autenticato che ha creato la segnalazione, proprietario o meccanico.';
comment on column public.future_work_records.mechanic_id is
  'Valorizzato solo quando la segnalazione viene creata dal meccanico.';
comment on table public.future_work_items is
  'Voci testuali appartenenti a un gruppo di lavori futuri.';

create index future_work_records_vehicle_open_idx
on public.future_work_records(vehicle_id, done, created_at desc);

create index future_work_records_mechanic_idx
on public.future_work_records(mechanic_id)
where mechanic_id is not null;

create index future_work_items_record_idx
on public.future_work_items(record_id, created_at, id);

alter table public.future_work_records enable row level security;
alter table public.future_work_items enable row level security;

revoke all on table public.future_work_records from anon, authenticated;
revoke all on table public.future_work_items from anon, authenticated;
grant select, insert, delete on table public.future_work_records to authenticated;
grant update(done) on table public.future_work_records to authenticated;
grant select, insert, delete on table public.future_work_items to authenticated;
grant update(description) on table public.future_work_items to authenticated;

create policy future_work_records_select
on public.future_work_records
for select
to authenticated
using (
  (select auth.uid()) is not null
  and (
    public.is_vehicle_owned_by_current_user(vehicle_id)
    or public.is_vehicle_assigned_to_current_mechanic(vehicle_id)
  )
);

create policy future_work_records_insert
on public.future_work_records
for insert
to authenticated
with check (
  created_by_user_id = (select auth.uid())
  and (
    (
      mechanic_id is null
      and public.is_vehicle_owned_by_current_user(vehicle_id)
    )
    or exists (
      select 1
      from public.mechanics m
      join public.vehicle_mechanics vm on vm.mechanic_id = m.id
      where m.id = future_work_records.mechanic_id
        and m.user_id = (select auth.uid())
        and m.is_active = true
        and vm.vehicle_id = future_work_records.vehicle_id
    )
  )
);

create policy future_work_records_update
on public.future_work_records
for update
to authenticated
using (
  public.is_vehicle_owned_by_current_user(vehicle_id)
  or public.is_vehicle_assigned_to_current_mechanic(vehicle_id)
)
with check (
  public.is_vehicle_owned_by_current_user(vehicle_id)
  or public.is_vehicle_assigned_to_current_mechanic(vehicle_id)
);

create policy future_work_records_delete
on public.future_work_records
for delete
to authenticated
using (
  public.is_vehicle_owned_by_current_user(vehicle_id)
  or public.is_vehicle_assigned_to_current_mechanic(vehicle_id)
);

create policy future_work_items_select
on public.future_work_items
for select
to authenticated
using (
  exists (
    select 1
    from public.future_work_records r
    where r.id = future_work_items.record_id
      and (
        public.is_vehicle_owned_by_current_user(r.vehicle_id)
        or public.is_vehicle_assigned_to_current_mechanic(r.vehicle_id)
      )
  )
);

create policy future_work_items_insert
on public.future_work_items
for insert
to authenticated
with check (
  exists (
    select 1
    from public.future_work_records r
    where r.id = future_work_items.record_id
      and (
        public.is_vehicle_owned_by_current_user(r.vehicle_id)
        or public.is_vehicle_assigned_to_current_mechanic(r.vehicle_id)
      )
  )
);

create policy future_work_items_update
on public.future_work_items
for update
to authenticated
using (
  exists (
    select 1
    from public.future_work_records r
    where r.id = future_work_items.record_id
      and (
        public.is_vehicle_owned_by_current_user(r.vehicle_id)
        or public.is_vehicle_assigned_to_current_mechanic(r.vehicle_id)
      )
  )
)
with check (
  exists (
    select 1
    from public.future_work_records r
    where r.id = future_work_items.record_id
      and (
        public.is_vehicle_owned_by_current_user(r.vehicle_id)
        or public.is_vehicle_assigned_to_current_mechanic(r.vehicle_id)
      )
  )
);

create policy future_work_items_delete
on public.future_work_items
for delete
to authenticated
using (
  exists (
    select 1
    from public.future_work_records r
    where r.id = future_work_items.record_id
      and (
        public.is_vehicle_owned_by_current_user(r.vehicle_id)
        or public.is_vehicle_assigned_to_current_mechanic(r.vehicle_id)
      )
  )
);

create policy owner_registration_gate
on public.future_work_records
as restrictive
for all
to authenticated
using ((select private.owner_registration_ready()))
with check ((select private.owner_registration_ready()));

create policy owner_registration_gate
on public.future_work_items
as restrictive
for all
to authenticated
using ((select private.owner_registration_ready()))
with check ((select private.owner_registration_ready()));

create trigger require_owner_registration
before insert or update on public.future_work_records
for each row execute function private.require_owner_registration();

create trigger require_owner_registration
before insert or update on public.future_work_items
for each row execute function private.require_owner_registration();
