alter table public.future_work_records
  add column resolved_by_maintenance_record_id uuid
  references public.maintenance_records(id) on delete set null;

create index future_work_records_resolving_work_idx
  on public.future_work_records(resolved_by_maintenance_record_id)
  where resolved_by_maintenance_record_id is not null;

create function public.get_vehicle_open_work_log_reports(p_vehicle_id uuid)
returns jsonb
language sql stable security invoker set search_path = ''
as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'id', r.id,
    'description', coalesce(
      nullif(btrim(r.anomaly_description), ''),
      nullif(btrim(r.onboard_message), ''),
      case when r.anomaly_description is null then (
        select string_agg(i.description, E'\n' order by i.created_at, i.id)
        from public.future_work_items i where i.record_id = r.id
      ) end,
      ''
    ),
    'warning_lights', r.warning_lights
  ) order by r.created_at desc, r.id desc), '[]'::jsonb)
  from public.future_work_records r
  where r.vehicle_id = p_vehicle_id and not r.done;
$$;

revoke all on function public.get_vehicle_open_work_log_reports(uuid) from public, anon;
grant execute on function public.get_vehicle_open_work_log_reports(uuid) to authenticated;

-- The private function can write the link without granting direct UPDATE of
-- that column. The caller must own the vehicle or be its assigned mechanic.
create function automob_private.create_work_log_for_reports(p_report_ids uuid[], p_payload jsonb)
returns uuid
language plpgsql security definer set search_path = ''
as $$
declare
  v_vehicle_id uuid := (p_payload ->> 'vehicle_id')::uuid;
  v_expected_count integer;
  v_locked_count integer := 0;
  v_report record;
  v_work_id uuid;
begin
  if (select auth.uid()) is null or not (
    public.is_vehicle_owned_by_current_user(v_vehicle_id)
    or public.is_vehicle_assigned_to_current_mechanic(v_vehicle_id)
  ) then
    raise exception 'Veicolo non accessibile' using errcode = '42501';
  end if;

  if coalesce(cardinality(p_report_ids), 0) = 0 or array_position(p_report_ids, null) is not null then
    raise exception 'Selezione delle segnalazioni non valida' using errcode = '22023';
  end if;
  select count(distinct id) into v_expected_count from unnest(p_report_ids) as ids(id);

  -- Lock in a stable order before writing so concurrent submissions cannot
  -- both create a work record for the same open report.
  for v_report in
    select r.id, r.done from public.future_work_records r
    where r.vehicle_id = v_vehicle_id and r.id = any(p_report_ids)
    order by r.id for update
  loop
    if v_report.done then
      raise exception 'Le segnalazioni aperte sono cambiate' using errcode = 'PT409';
    end if;
    v_locked_count := v_locked_count + 1;
  end loop;
  if v_locked_count <> v_expected_count then
    raise exception 'Le segnalazioni aperte sono cambiate' using errcode = 'PT409';
  end if;

  v_work_id := public.crea_sessione_manutenzione(p_payload);
  update public.future_work_records
  set done = true, resolved_by_maintenance_record_id = v_work_id
  where vehicle_id = v_vehicle_id and id = any(p_report_ids);
  return v_work_id;
end;
$$;

revoke all on function automob_private.create_work_log_for_reports(uuid[], jsonb) from public, anon;
grant execute on function automob_private.create_work_log_for_reports(uuid[], jsonb) to authenticated;

create function public.create_work_log_for_reports(p_report_ids uuid[], p_payload jsonb)
returns uuid
language sql security invoker set search_path = ''
as $$
  select automob_private.create_work_log_for_reports(p_report_ids, p_payload);
$$;

revoke all on function public.create_work_log_for_reports(uuid[], jsonb) from public, anon;
grant execute on function public.create_work_log_for_reports(uuid[], jsonb) to authenticated;

notify pgrst, 'reload schema';
