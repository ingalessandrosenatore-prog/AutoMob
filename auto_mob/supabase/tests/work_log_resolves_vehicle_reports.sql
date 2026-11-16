-- Requires a vehicle assigned to an active mechanic. All writes roll back.
begin;
do $test$
declare
  v_vehicle uuid;
  v_owner uuid;
  v_mechanic uuid;
  v_km integer;
  v_first uuid;
  v_second uuid;
  v_unselected uuid;
  v_work uuid;
  v_payload jsonb;
  v_count bigint;
begin
  assert not has_function_privilege('anon', 'public.create_work_log_for_reports(uuid[],jsonb)', 'execute');
  assert not has_column_privilege('authenticated', 'public.future_work_records', 'resolved_by_maintenance_record_id', 'update');

  select v.id, v.owner_id, m.user_id, v.km_current
  into v_vehicle, v_owner, v_mechanic, v_km
  from public.vehicles v
  join public.vehicle_mechanics vm on vm.vehicle_id = v.id
  join public.mechanics m on m.id = vm.mechanic_id
  where m.is_active and m.user_id <> v.owner_id
  limit 1;
  if v_vehicle is null then raise exception 'An assigned vehicle fixture is required'; end if;

  perform set_config('request.jwt.claim.sub', v_owner::text, true);
  execute 'set local role authenticated';
  v_first := public.create_future_work_report(v_vehicle, 'Rumore', current_date + 1, '', '[]');
  v_second := public.create_future_work_report(v_vehicle, '', current_date + 1, 'Messaggio bordo', '[]');
  v_unselected := public.create_future_work_report(v_vehicle, 'Controllo rinviato', current_date + 1, '', '[]');

  perform set_config('request.jwt.claim.sub', v_mechanic::text, true);
  assert exists (select 1 from jsonb_array_elements(public.get_vehicle_open_work_log_reports(v_vehicle)) r
    where r->>'id' = v_second::text and r->>'description' = 'Messaggio bordo');
  v_payload := jsonb_build_object('vehicle_id', v_vehicle, 'type', 'altro',
    'custom_name', 'Verifica', 'notes', E'Verifica - Nessuna spia - Rumore\nVerifica - Nessuna spia - Messaggio bordo',
    'service_km', v_km, 'service_date', current_date, 'parts', '[]'::jsonb);
  select count(*) into v_count from public.maintenance_records where vehicle_id = v_vehicle;

  begin
    perform public.create_work_log_for_reports(array[v_first, gen_random_uuid()], v_payload);
    raise exception 'Invalid selection accepted';
  exception when sqlstate 'PT409' then null;
  end;
  begin
    perform public.create_work_log_for_reports(array[v_first, v_second], v_payload || '{"parts":[{"part_id":-1}]}'::jsonb);
    raise exception 'Invalid work accepted';
  exception when foreign_key_violation then null;
  end;
  assert (select count(*) from public.maintenance_records where vehicle_id = v_vehicle) = v_count;
  assert not exists (select 1 from public.future_work_records where id in (v_first, v_second) and done);

  v_work := public.create_work_log_for_reports(array[v_first, v_second], v_payload);
  assert (select count(*) from public.future_work_records
    where id in (v_first, v_second) and done and resolved_by_maintenance_record_id = v_work) = 2;
  assert (select not done and resolved_by_maintenance_record_id is null from public.future_work_records where id = v_unselected);
  assert (select notes from public.maintenance_items where record_id = v_work) = v_payload->>'notes';
  assert not exists (select 1 from jsonb_array_elements(public.get_vehicle_open_work_log_reports(v_vehicle)) r
    where r->>'id' in (v_first::text, v_second::text));
  begin
    perform public.create_work_log_for_reports(array[v_first, v_unselected], v_payload);
    raise exception 'Stale work accepted';
  exception when sqlstate 'PT409' then null;
  end;
  assert (select not done from public.future_work_records where id = v_unselected);

  perform set_config('request.jwt.claim.sub', gen_random_uuid()::text, true);
  assert public.get_vehicle_open_work_log_reports(v_vehicle) = '[]'::jsonb;
  begin
    perform public.create_work_log_for_reports(array[v_unselected], v_payload);
    raise exception 'Unrelated user accepted';
  exception when insufficient_privilege then null;
  end;

  perform set_config('request.jwt.claim.sub', v_owner::text, true);
  assert not exists (select 1 from jsonb_array_elements(public.get_owner_active_reports()) r
    where r->>'record_id' in (v_first::text, v_second::text));
  v_work := public.create_work_log_for_reports(array[v_unselected], v_payload);
  assert (select resolved_by_maintenance_record_id from public.future_work_records where id = v_unselected) = v_work;
  execute 'reset role';
end;
$test$;
rollback;
