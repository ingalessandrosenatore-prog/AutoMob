-- A report keeps the odometer reading observed at creation; legacy rows stay unknown.
alter table public.future_work_records add column reported_km integer
  check (reported_km >= 0);

create or replace function public.create_future_work_report(
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
  insert into public.future_work_records(vehicle_id, created_by_user_id, mechanic_id, reminder_date, anomaly_description, onboard_message, warning_lights, reported_km)
  values (p_vehicle_id, (select auth.uid()), null, p_reminder_date, btrim(p_description), btrim(p_onboard_message), p_warning_lights, (select v.km_current from public.vehicles v where v.id = p_vehicle_id))
  returning id into v_record_id;
  -- Compatibility summary for clients that only know future_work_items.
  insert into public.future_work_items(record_id, description)
  values (v_record_id, coalesce(nullif(btrim(p_description), ''), nullif(btrim(p_onboard_message), ''), 'Spie segnalate'));
  return v_record_id;
end;
$$;
revoke all on function public.create_future_work_report(uuid,text,date,text,jsonb) from public, anon;
grant execute on function public.create_future_work_report(uuid,text,date,text,jsonb) to authenticated;

create or replace function public.get_owner_active_reports()
returns jsonb language sql stable security invoker set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', i.id, 'record_id', r.id, 'vehicle_id', r.vehicle_id,
    'description', coalesce(r.anomaly_description, i.description),
    'onboard_message', r.onboard_message, 'warning_lights', r.warning_lights,
    'reported_km', r.reported_km, 'registered_at', r.created_at, 'reminder_date', r.reminder_date
  ) order by r.created_at desc, i.created_at desc, i.id desc), '[]'::jsonb)
  from public.future_work_records r
  join public.future_work_items i on i.record_id = r.id
  where not r.done and public.is_vehicle_owned_by_current_user(r.vehicle_id);
$$;
revoke all on function public.get_owner_active_reports() from public, anon;
grant execute on function public.get_owner_active_reports() to authenticated;

-- Keep work creation and report resolution in one transaction. The row lock
-- prevents two concurrent wizard submissions from creating duplicate work.
create function public.create_work_log_for_report(p_report_id uuid, p_payload jsonb)
returns uuid language plpgsql security invoker set search_path = ''
as $$
declare
  v_vehicle_id uuid;
  v_done boolean;
  v_work_id uuid;
begin
  select r.vehicle_id, r.done into v_vehicle_id, v_done
  from public.future_work_records r
  where r.id = p_report_id
    and public.is_vehicle_owned_by_current_user(r.vehicle_id)
  for update;
  if not found then
    raise exception 'Segnalazione non accessibile' using errcode = '42501';
  end if;
  if v_done then
    raise exception 'La segnalazione è già stata risolta. Aggiorna la schermata.' using errcode = '22023';
  end if;
  if (p_payload ->> 'vehicle_id')::uuid is distinct from v_vehicle_id then
    raise exception 'Il lavoro deve appartenere al veicolo della segnalazione' using errcode = '22023';
  end if;
  v_work_id := public.crea_sessione_manutenzione(p_payload);
  perform public.complete_future_work_report(p_report_id);
  return v_work_id;
end;
$$;
revoke all on function public.create_work_log_for_report(uuid,jsonb) from public, anon;
grant execute on function public.create_work_log_for_report(uuid,jsonb) to authenticated;
