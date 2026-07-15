-- Registrazione veicolo: lookup temporaneo InfoTarga e snapshot permanente.
-- La migrazione non amplia i permessi del meccanico sugli interventi: quella
-- revisione RLS è intenzionalmente rinviata a una sessione dedicata.

create table if not exists public.vehicle_lookup_results (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  plate text not null,
  status text not null check (status in ('complete', 'partial')),
  provider_code text not null,
  core_data jsonb not null default '{}'::jsonb,
  raw_payload jsonb not null,
  trace_id text,
  created_at timestamptz not null default now(),
  expires_at timestamptz not null default (now() + interval '7 days')
);

create index if not exists vehicle_lookup_results_owner_created_idx
  on public.vehicle_lookup_results(owner_id, created_at desc);
create index if not exists vehicle_lookup_results_expiry_idx
  on public.vehicle_lookup_results(expires_at);

alter table public.vehicle_lookup_results enable row level security;
drop policy if exists lookup_results_select_owner on public.vehicle_lookup_results;
create policy lookup_results_select_owner
  on public.vehicle_lookup_results for select to authenticated
  using (owner_id = auth.uid());
revoke all on public.vehicle_lookup_results from anon, authenticated;
grant select on public.vehicle_lookup_results to authenticated;

create table if not exists public.vehicle_external_snapshots (
  vehicle_id uuid primary key references public.vehicles(id) on delete cascade,
  lookup_id uuid references public.vehicle_lookup_results(id) on delete set null,
  provider text not null default 'infotarga',
  queried_plate text not null,
  quality text not null check (quality in ('complete', 'partial')),
  provider_code text not null,
  raw_payload jsonb not null,
  insurance_compliant boolean,
  has_insurance boolean,
  insurance_company text,
  policy_expiry_date date,
  emissions_class text,
  novice_driver boolean,
  inspection_compliant boolean,
  inspection_next_due_date date,
  theft_exists boolean,
  provider_refreshed_at timestamptz,
  created_at timestamptz not null default now()
);

alter table public.vehicle_external_snapshots enable row level security;
drop policy if exists external_snapshots_select_owner on public.vehicle_external_snapshots;
create policy external_snapshots_select_owner
  on public.vehicle_external_snapshots for select to authenticated
  using (exists (
    select 1 from public.vehicles v
    where v.id = vehicle_external_snapshots.vehicle_id
      and v.owner_id = auth.uid()
  ));
drop policy if exists external_snapshots_insert_owner on public.vehicle_external_snapshots;
create policy external_snapshots_insert_owner
  on public.vehicle_external_snapshots for insert to authenticated
  with check (exists (
    select 1 from public.vehicles v
    where v.id = vehicle_external_snapshots.vehicle_id
      and v.owner_id = auth.uid()
  ));
revoke all on public.vehicle_external_snapshots from anon, authenticated;
grant select, insert on public.vehicle_external_snapshots to authenticated;

-- Il lookup del codice officina è disponibile solo a utenti autenticati.
alter table public.mechanics enable row level security;
drop policy if exists mechanics_select_active_public on public.mechanics;
drop policy if exists mechanics_select_own on public.mechanics;
drop policy if exists mechanics_update_own on public.mechanics;
create policy mechanics_select_active_authenticated
  on public.mechanics for select to authenticated
  using (is_active = true or user_id = auth.uid());
create policy mechanics_update_own_authenticated
  on public.mechanics for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

create or replace function public.crea_veicolo_con_storico(p_payload jsonb)
returns uuid
language plpgsql
set search_path to 'public'
as $function$
declare
  v_owner uuid := auth.uid();
  v_veicolo jsonb := p_payload -> 'veicolo';
  v_lavori jsonb := coalesce(p_payload -> 'lavori', '[]'::jsonb);
  v_vehicle_id uuid;
  v_record_id uuid;
  v_lavoro jsonb;
  v_mechanic_id uuid := nullif(p_payload ->> 'mechanic_id', '')::uuid;
  v_mechanic_code text := nullif(p_payload ->> 'mechanic_code', '');
  v_lookup_id uuid := nullif(p_payload ->> 'lookup_id', '')::uuid;
  v_lookup public.vehicle_lookup_results%rowtype;
begin
  if v_owner is null then
    raise exception 'Utente non autenticato' using errcode = '28000';
  end if;
  if v_veicolo is null then
    raise exception 'Payload veicolo assente' using errcode = '22023';
  end if;

  insert into public.vehicles (
    owner_id, plate, brand, model, year, fuel,
    power_cv, displacement_cc, km_current, scadenza_revision_date,
    tagliando_interval_km, distribution_intervall_km,
    tire_change_interval_km, tire_rotation_interval_km
  ) values (
    v_owner,
    lower(v_veicolo ->> 'plate'),
    lower(v_veicolo ->> 'brand'),
    lower(v_veicolo ->> 'model'),
    (v_veicolo ->> 'year')::int,
    lower(v_veicolo ->> 'fuel'),
    (v_veicolo ->> 'power_cv')::int,
    (v_veicolo ->> 'displacement_cc')::int,
    coalesce((v_veicolo ->> 'km_current')::int, 0),
    (v_veicolo ->> 'scadenza_revision_date')::date,
    coalesce((v_veicolo ->> 'tagliando_interval_km')::int, 15000),
    (v_veicolo ->> 'distribution_intervall_km')::int,
    coalesce((v_veicolo ->> 'tire_change_interval_km')::int, 40000),
    coalesce((v_veicolo ->> 'tire_rotation_interval_km')::int, 10000)
  ) returning id into v_vehicle_id;

  if jsonb_array_length(v_lavori) > 0 then
    insert into public.maintenance_records (vehicle_id, service_date)
    values (v_vehicle_id, current_date) returning id into v_record_id;
    for v_lavoro in select * from jsonb_array_elements(v_lavori) loop
      insert into public.maintenance_items (
        record_id, type, service_km, service_date
      ) values (
        v_record_id,
        v_lavoro ->> 'type',
        (v_lavoro ->> 'service_km')::int,
        current_date
      );
    end loop;
  end if;

  if v_mechanic_id is not null then
    if not exists (
      select 1 from public.mechanics m
      where m.id = v_mechanic_id and m.mechanic_code = v_mechanic_code
        and m.is_active = true
    ) then
      raise exception 'Meccanico non valido o non attivo' using errcode = '22023';
    end if;
    insert into public.vehicle_mechanics(vehicle_id, mechanic_id)
    values (v_vehicle_id, v_mechanic_id);
  end if;

  if v_lookup_id is not null then
    select * into v_lookup from public.vehicle_lookup_results l
    where l.id = v_lookup_id and l.owner_id = v_owner
      and l.expires_at > now();
    if not found then
      raise exception 'Lookup non valido, scaduto o non appartenente all utente'
        using errcode = '22023';
    end if;
    if upper(v_lookup.plate) <> upper(v_veicolo ->> 'plate') then
      raise exception 'La targa del lookup non coincide con il veicolo'
        using errcode = '22023';
    end if;

    insert into public.vehicle_external_snapshots (
      vehicle_id, lookup_id, queried_plate, quality, provider_code, raw_payload,
      insurance_compliant, has_insurance, insurance_company,
      policy_expiry_date, emissions_class, novice_driver,
      inspection_compliant, inspection_next_due_date, theft_exists,
      provider_refreshed_at
    ) values (
      v_vehicle_id, v_lookup.id, v_lookup.plate, v_lookup.status,
      v_lookup.provider_code, v_lookup.raw_payload,
      (v_lookup.raw_payload #>> '{data,insurance,compliant}')::boolean,
      (v_lookup.raw_payload #>> '{data,insurance,hasInsurance}')::boolean,
      v_lookup.raw_payload #>> '{data,insurance,insuranceCompany}',
      to_date(
        nullif(v_lookup.raw_payload #>> '{data,insurance,policyExpiryDate}', ''),
        'DD/MM/YYYY'
      ),
      v_lookup.raw_payload #>> '{data,emissions,class}',
      (v_lookup.raw_payload #>> '{data,licenseEligibility,noviceDriver}')::boolean,
      (v_lookup.raw_payload #>> '{data,inspection,compliant}')::boolean,
      to_date(
        nullif(v_lookup.raw_payload #>> '{data,inspection,nextDueDate}', ''),
        'DD/MM/YYYY'
      ),
      (v_lookup.raw_payload #>> '{data,theft,exists}')::boolean,
      case when (v_lookup.raw_payload ->> 'timestamp') ~ '^[0-9]+$'
        then to_timestamp((v_lookup.raw_payload ->> 'timestamp')::double precision / 1000)
      end
    );
  end if;

  return v_vehicle_id;
end;
$function$;

revoke all on function public.crea_veicolo_con_storico(jsonb) from public, anon;
grant execute on function public.crea_veicolo_con_storico(jsonb) to authenticated;
