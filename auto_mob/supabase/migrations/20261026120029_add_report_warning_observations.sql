-- Observations describe what the driver saw, never an inferred diagnosis.
alter table public.future_work_records
  add column onboard_message text not null default '' check (length(onboard_message) <= 1000),
  add column anomaly_description text check (length(anomaly_description) <= 1000),
  add column warning_lights jsonb not null default '[]'::jsonb;

create function public.valid_report_warning_lights(p_lights jsonb)
returns boolean language plpgsql immutable security invoker set search_path = ''
as $$
declare v_light jsonb; v_codes text[] := '{}';
begin
  if p_lights is null or jsonb_typeof(p_lights) <> 'array' then return false; end if;
  if jsonb_array_length(p_lights) > 43 then return false; end if;
  for v_light in select value from jsonb_array_elements(p_lights) loop
    if jsonb_typeof(v_light) <> 'object'
      or not (v_light ?& array['code','color','flashing'])
      or jsonb_typeof(v_light->'code') <> 'string'
      or (v_light->>'code') !~ '^(S(0[1-9]|[1-3][0-9]|40)|STOP|SERVICE|OTHER)$'
      or jsonb_typeof(v_light->'color') <> 'string'
      or (v_light->>'color') not in ('red','amber','green','blue','white','unknown')
      or jsonb_typeof(v_light->'flashing') <> 'boolean'
      or (v_light->>'code') = any(v_codes)
    then return false; end if;
    v_codes := array_append(v_codes, v_light->>'code');
  end loop;
  return true;
end;
$$;
revoke all on function public.valid_report_warning_lights(jsonb) from public, anon;
grant execute on function public.valid_report_warning_lights(jsonb) to authenticated;

alter table public.future_work_records
  add constraint future_work_warning_lights_valid check (public.valid_report_warning_lights(warning_lights)),
  add constraint future_work_observation_present check (
    anomaly_description is null -- Existing records retain their original item descriptions.
    or length(btrim(anomaly_description)) > 0
    or length(btrim(onboard_message)) > 0
    or jsonb_array_length(warning_lights) > 0
  );

-- Keep the original three-argument RPC for previously released clients.
create function public.create_future_work_report(
  p_vehicle_id uuid, p_description text, p_reminder_date date,
  p_onboard_message text, p_warning_lights jsonb
)
returns uuid language plpgsql security invoker set search_path = ''
as $$
declare v_record_id uuid;
begin
  if (select auth.uid()) is null then
    raise exception 'Utente non autenticato' using errcode = '42501';
  end if;
  if not public.is_vehicle_owned_by_current_user(p_vehicle_id) then
    raise exception 'Veicolo non accessibile' using errcode = '42501';
  end if;
  if p_description is null or p_onboard_message is null
    or length(btrim(p_description)) > 1000 or length(btrim(p_onboard_message)) > 1000
    or not public.valid_report_warning_lights(p_warning_lights)
    or (length(btrim(p_description)) = 0 and length(btrim(p_onboard_message)) = 0 and jsonb_array_length(p_warning_lights) = 0)
  then raise exception 'Inserisci una spia, un messaggio o una descrizione valida' using errcode = '22023'; end if;
  if p_reminder_date is null or p_reminder_date < current_date then
    raise exception 'Data di richiamo non valida' using errcode = '22023';
  end if;
  insert into public.future_work_records(vehicle_id, created_by_user_id, mechanic_id, reminder_date, anomaly_description, onboard_message, warning_lights)
  values (p_vehicle_id, (select auth.uid()), null, p_reminder_date, btrim(p_description), btrim(p_onboard_message), p_warning_lights)
  returning id into v_record_id;
  -- Compatibility summary for clients that only know future_work_items.
  insert into public.future_work_items(record_id, description)
  values (v_record_id, coalesce(nullif(btrim(p_description), ''), nullif(btrim(p_onboard_message), ''), 'Spie segnalate'));
  return v_record_id;
end;
$$;
revoke all on function public.create_future_work_report(uuid,text,date,text,jsonb) from public, anon;
grant execute on function public.create_future_work_report(uuid,text,date,text,jsonb) to authenticated;

create function public.complete_future_work_report(p_record_id uuid)
returns void language plpgsql security invoker set search_path = ''
as $$
begin
  -- RLS and the column-level grant allow only an accessible record's done flag.
  update public.future_work_records set done = true where id = p_record_id;
  if not found then
    raise exception 'Segnalazione non accessibile' using errcode = '42501';
  end if;
end;
$$;
revoke all on function public.complete_future_work_report(uuid) from public, anon;
grant execute on function public.complete_future_work_report(uuid) to authenticated;

-- Scalar JSON avoids the Data API row cap; all open observations reach cards.
create function public.get_owner_active_reports()
returns jsonb language sql stable security invoker set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', i.id, 'record_id', r.id, 'vehicle_id', r.vehicle_id,
    'description', coalesce(r.anomaly_description, i.description),
    'onboard_message', r.onboard_message, 'warning_lights', r.warning_lights,
    'registered_at', r.created_at, 'reminder_date', r.reminder_date
  ) order by r.created_at desc, i.created_at desc, i.id desc), '[]'::jsonb)
  from public.future_work_records r
  join public.future_work_items i on i.record_id = r.id
  where not r.done and public.is_vehicle_owned_by_current_user(r.vehicle_id);
$$;
revoke all on function public.get_owner_active_reports() from public, anon;
grant execute on function public.get_owner_active_reports() to authenticated;

create or replace function public.get_mechanic_future_work_catalog()
returns jsonb language sql stable security invoker set search_path = ''
as $$
  with visible_reports as (
    select r.*, v.brand, v.model, v.plate,
      (select string_agg(i.description, E'\n' order by i.created_at, i.id)
       from public.future_work_items i where i.record_id = r.id) as legacy_description
    from public.future_work_records r
    join public.vehicles v on v.id = r.vehicle_id
    where not r.done and exists (
      select 1 from public.vehicle_mechanics vm
      join public.mechanics m on m.id = vm.mechanic_id
      where vm.vehicle_id = r.vehicle_id and m.user_id = (select auth.uid()) and m.is_active
    )
  ), vehicle_requests as (
    select vehicle_id, concat_ws(' ', nullif(trim(brand), ''), nullif(trim(model), '')) as vehicle_model,
      plate, max(created_at) as registered_at, min(reminder_date) as reminder_date,
      jsonb_agg(coalesce(nullif(anomaly_description, ''), legacy_description) order by created_at desc, id desc) as issues,
      jsonb_agg(jsonb_build_object(
        'record_id', id, 'description', coalesce(anomaly_description, legacy_description, ''),
        'onboard_message', onboard_message, 'warning_lights', warning_lights
      ) order by created_at desc, id desc) as reports
    from visible_reports group by vehicle_id, brand, model, plate
  )
  select coalesce(jsonb_agg(to_jsonb(vehicle_requests) || jsonb_build_object('id', vehicle_id)
    order by registered_at desc, vehicle_id desc), '[]'::jsonb) from vehicle_requests;
$$;
revoke all on function public.get_mechanic_future_work_catalog() from public, anon;
grant execute on function public.get_mechanic_future_work_catalog() to authenticated;
CREATE OR REPLACE FUNCTION public.get_mechanic_home_catalog()
 RETURNS jsonb
 LANGUAGE sql
 STABLE
 SET search_path TO ''
AS $function$
  with session_context as (
    select m.id as mechanic_id,
      coalesce(nullif(trim(p.full_name), ''), nullif(trim(m.business_name), ''), 'Meccanico') as display_name,
      m.business_name, m.mechanic_code
    from (select auth.uid() as user_id) session
    left join public.profiles p on p.id = session.user_id
    left join public.mechanics m on m.user_id = session.user_id and m.is_active = true
  ),
  linked_vehicles as (
    select distinct v.id, v.plate, v.brand, v.model, v.year, v.fuel, v.power_cv,
      v.displacement_cc, v.km_current, v.scadenza_revision_date,
      v.tagliando_interval_km, v.distribution_intervall_km,
      v.tire_change_interval_km, v.tire_rotation_interval_km,
      v.created_at, v.updated_at
    from session_context sc
    join public.vehicle_mechanics vm on vm.mechanic_id = sc.mechanic_id
    join public.vehicles v on v.id = vm.vehicle_id
  ),
  last_service_km as (
    select mr.vehicle_id,
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
        'id', lv.id, 'plate', lv.plate, 'brand', lv.brand, 'model', lv.model,
        'year', lv.year, 'fuel', lv.fuel, 'power_cv', lv.power_cv,
        'displacement_cc', lv.displacement_cc, 'km_current', lv.km_current,
        'scadenza_revision_date', lv.scadenza_revision_date,
        'tagliando_interval_km', lv.tagliando_interval_km,
        'distribution_intervall_km', lv.distribution_intervall_km,
        'tire_change_interval_km', lv.tire_change_interval_km,
        'tire_rotation_interval_km', lv.tire_rotation_interval_km,
        'last_tagliando_km', lsk.last_tagliando_km,
        'last_distribuzione_km', lsk.last_distribuzione_km,
        'created_at', lv.created_at, 'updated_at', lv.updated_at,
        'warning_lights', (
          select coalesce(jsonb_agg(distinct light.value), '[]'::jsonb)
          from public.future_work_records r
          cross join lateral jsonb_array_elements(r.warning_lights) light
          where r.vehicle_id = lv.id and not r.done
        )
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
  from session_context sc cross join catalog;
$function$
