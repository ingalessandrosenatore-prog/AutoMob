-- No fixtures or work logs survive this transaction.
begin;
do $test$
declare
  v_vehicle uuid; v_owner uuid; v_km integer; v_report uuid; v_work uuid;
  v_payload jsonb; v_count bigint;
begin
  assert not has_function_privilege('anon', 'public.create_work_log_for_report(uuid,jsonb)', 'execute');
  select id, owner_id, km_current into v_vehicle, v_owner, v_km from public.vehicles limit 1;
  if v_vehicle is null then raise exception 'A vehicle fixture is required'; end if;
  perform set_config('request.jwt.claim.sub', v_owner::text, true);
  execute 'set local role authenticated';
  v_report := public.create_future_work_report(v_vehicle, 'Test anomalia', current_date + 1, 'Test bordo', '[]'::jsonb);
  assert (select reported_km from public.future_work_records where id = v_report) = v_km;
  assert exists (select 1 from jsonb_array_elements(public.get_owner_active_reports()) x
    where x->>'record_id' = v_report::text and (x->>'reported_km')::integer = v_km);
  v_payload := jsonb_build_object('vehicle_id', v_vehicle, 'type', 'altro',
    'custom_name', 'Test spia', 'notes', 'Test bordo', 'service_km', v_km,
    'service_date', current_date, 'parts', '[]'::jsonb);
  select count(*) into v_count from public.maintenance_records where vehicle_id = v_vehicle;
  begin
    -- Invalid part fails after the maintenance row insert: the entire save rolls back.
    perform public.create_work_log_for_report(v_report,
      v_payload || '{"parts":[{"part_id":-1}]}'::jsonb);
    raise exception 'Invalid work was accepted';
  exception when foreign_key_violation then null;
  end;
  assert not (select done from public.future_work_records where id = v_report);
  assert (select count(*) from public.maintenance_records where vehicle_id = v_vehicle) = v_count;
  begin
    perform public.create_work_log_for_report(v_report,
      v_payload || jsonb_build_object('vehicle_id', gen_random_uuid()));
    raise exception 'Mismatched vehicle accepted';
  exception when invalid_parameter_value then null;
  end;
  v_work := public.create_work_log_for_report(v_report, v_payload);
  assert (select done from public.future_work_records where id = v_report);
  assert exists (select 1 from public.maintenance_items where record_id = v_work
    and type = 'altro' and custom_name = 'Test spia' and notes = 'Test bordo');
  assert not exists (select 1 from jsonb_array_elements(public.get_owner_active_reports()) x
    where x->>'record_id' = v_report::text);
  begin
    perform public.create_work_log_for_report(v_report, v_payload);
    raise exception 'Repeated work accepted';
  exception when invalid_parameter_value then null;
  end;
  assert (select count(*) from public.maintenance_records where vehicle_id = v_vehicle) = v_count + 1;
  execute 'reset role';
  perform set_config('request.jwt.claim.sub', gen_random_uuid()::text, true);
  execute 'set local role authenticated';
  begin
    perform public.create_work_log_for_report(v_report, v_payload);
    raise exception 'Unrelated user accepted';
  exception when insufficient_privilege then null;
  end;
  execute 'reset role';
end;
$test$;
rollback;
