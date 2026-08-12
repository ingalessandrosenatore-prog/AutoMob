alter table public.vehicles
  alter column tagliando_interval_km set default 15000,
  alter column distribution_intervall_km set default 100000,
  alter column tire_change_interval_km set default 40000,
  alter column tire_rotation_interval_km set default 15000;

update public.vehicles
set distribution_intervall_km = coalesce(distribution_intervall_km, 100000);

create or replace function public.crea_veicolo_con_storico(p_payload jsonb)
returns uuid
language plpgsql
set search_path to 'public'
as $function$
declare
  v_owner uuid := auth.uid();
  v_veicolo jsonb := p_payload -> 'veicolo';
  v_lavori jsonb := coalesce(
    p_payload -> 'lavori',
    jsonb_build_array(
      jsonb_build_object('type', 'tagliando', 'service_km', 0),
      jsonb_build_object('type', 'distribuzione', 'service_km', 0),
      jsonb_build_object('type', 'pneumatici_cambio', 'service_km', 0),
      jsonb_build_object('type', 'pneumatici_inversione', 'service_km', 0)
    )
  );
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

  if jsonb_array_length(v_lavori) = 0 then
    v_lavori := jsonb_build_array(
      jsonb_build_object('type', 'tagliando', 'service_km', 0),
      jsonb_build_object('type', 'distribuzione', 'service_km', 0),
      jsonb_build_object('type', 'pneumatici_cambio', 'service_km', 0),
      jsonb_build_object('type', 'pneumatici_inversione', 'service_km', 0)
    );
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
    coalesce((v_veicolo ->> 'distribution_intervall_km')::int, 100000),
    coalesce((v_veicolo ->> 'tire_change_interval_km')::int, 40000),
    coalesce((v_veicolo ->> 'tire_rotation_interval_km')::int, 15000)
  ) returning id into v_vehicle_id;

  insert into public.maintenance_records (vehicle_id, service_date)
  values (v_vehicle_id, current_date) returning id into v_record_id;
  for v_lavoro in select * from jsonb_array_elements(v_lavori) loop
    insert into public.maintenance_items (
      record_id, type, service_km, service_date
    ) values (
      v_record_id,
      v_lavoro ->> 'type',
      coalesce((v_lavoro ->> 'service_km')::int, 0),
      current_date
    );
  end loop;

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
