update public.parts
set category = 'cambio'::public.part_category
where id between 36 and 43;

alter table public.maintenance_items
  drop constraint type_valid,
  drop constraint custom_name_by_work_type;

alter table public.maintenance_items
  add constraint type_valid check (
    type = any (array[
      'tagliando',
      'distribuzione',
      'revisione',
      'pneumatici_cambio',
      'pneumatici_inversione',
      'motore',
      'freni',
      'telaio',
      'elettronica',
      'batteria',
      'cambio',
      'altro'
    ])
  ),
  add constraint custom_name_by_work_type check (
    (
      type = 'altro'
      and custom_name is not null
      and length(btrim(custom_name)) > 0
    )
    or (
      type = any (
        array[
          'motore',
          'freni',
          'telaio',
          'elettronica',
          'batteria',
          'cambio'
        ]
      )
      and (custom_name is null or length(btrim(custom_name)) > 0)
    )
    or (
      type = any (array[
        'tagliando',
        'distribuzione',
        'revisione',
        'pneumatici_cambio',
        'pneumatici_inversione'
      ])
      and custom_name is null
    )
  );

create or replace function automob_private.create_work_log(p_payload jsonb)
returns uuid
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_actor_id uuid := auth.uid();
  v_vehicle_id uuid := (p_payload ->> 'vehicle_id')::uuid;
  v_type text := p_payload ->> 'type';
  v_custom_name text := p_payload ->> 'custom_name';
  v_service_km int := (p_payload ->> 'service_km')::int;
  v_service_date date := coalesce((p_payload ->> 'service_date')::date, current_date);
  v_notes text := p_payload ->> 'notes';
  v_interval_km int := nullif(p_payload ->> 'interval_km', '')::int;
  v_parts jsonb := coalesce(p_payload -> 'parts', '[]'::jsonb);
  v_owner_id uuid;
  v_assigned_mechanic_id uuid;
  v_record_mechanic_id uuid;
  v_record_id uuid;
  v_item_id uuid;
  v_part jsonb;
begin
  if v_actor_id is null then
    raise exception 'Utente non autenticato' using errcode = '28000';
  end if;

  if v_vehicle_id is null then
    raise exception 'Veicolo non specificato' using errcode = '22023';
  end if;

  select
    v.owner_id,
    (
      select m.id
      from public.vehicle_mechanics vm
      join public.mechanics m on m.id = vm.mechanic_id
      where vm.vehicle_id = v.id
        and m.user_id = v_actor_id
        and m.is_active = true
      order by vm.assigned_at desc
      limit 1
    )
  into v_owner_id, v_assigned_mechanic_id
  from public.vehicles v
  where v.id = v_vehicle_id;

  if not found then
    raise exception 'Veicolo inesistente' using errcode = 'P0002';
  end if;

  if v_owner_id <> v_actor_id and v_assigned_mechanic_id is null then
    raise exception 'Non autorizzato a registrare lavori su questo veicolo'
      using errcode = '42501';
  end if;

  if v_service_km is null or v_service_km < 0 then
    raise exception 'Chilometraggio non valido' using errcode = '22023';
  end if;

  if v_parts is null or jsonb_typeof(v_parts) <> 'array' then
    raise exception 'Elenco ricambi non valido' using errcode = '22023';
  end if;

  v_record_mechanic_id := case
    when v_owner_id = v_actor_id then null
    else v_assigned_mechanic_id
  end;

  insert into public.maintenance_records (vehicle_id, service_date, mechanic_id)
  values (v_vehicle_id, v_service_date, v_record_mechanic_id)
  returning id into v_record_id;

  insert into public.maintenance_items (
    record_id,
    type,
    custom_name,
    service_km,
    service_date,
    notes
  )
  values (
    v_record_id,
    v_type,
    case
      when v_type = any (
        array[
          'motore',
          'freni',
          'telaio',
          'elettronica',
          'batteria',
          'cambio',
          'altro'
        ]
      ) then nullif(btrim(v_custom_name), '')
      else null
    end,
    v_service_km,
    v_service_date,
    v_notes
  )
  returning id into v_item_id;

  perform set_config('app.tipo_evento_km', 'manutenzione', true);

  update public.vehicles
  set km_current = greatest(km_current, v_service_km),
      tagliando_interval_km = case
        when v_type = 'tagliando' and coalesce(v_interval_km, 0) > 0
          then v_interval_km else tagliando_interval_km end,
      distribution_intervall_km = case
        when v_type = 'distribuzione' and coalesce(v_interval_km, 0) > 0
          then v_interval_km else distribution_intervall_km end,
      tire_change_interval_km = case
        when v_type = 'pneumatici_cambio' and coalesce(v_interval_km, 0) > 0
          then v_interval_km else tire_change_interval_km end,
      tire_rotation_interval_km = case
        when v_type = 'pneumatici_inversione' and coalesce(v_interval_km, 0) > 0
          then v_interval_km else tire_rotation_interval_km end
  where id = v_vehicle_id;

  for v_part in
    select value from jsonb_array_elements(v_parts)
  loop
    insert into public.maintenance_item_parts (
      item_id,
      part_id,
      quantity,
      unit_price,
      notes
    )
    values (
      v_item_id,
      (v_part ->> 'part_id')::bigint,
      coalesce((v_part ->> 'quantity')::numeric, 1),
      nullif(v_part ->> 'unit_price', '')::numeric,
      v_part ->> 'notes'
    );
  end loop;

  return v_record_id;
end;
$function$;

notify pgrst, 'reload schema';
