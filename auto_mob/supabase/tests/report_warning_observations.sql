-- Integration assertions run in a rollback-only transaction.
begin;
do $test$
begin
  assert public.valid_report_warning_lights('[]'::jsonb);
  assert public.valid_report_warning_lights('[{"code":"S03","color":"amber","flashing":true}]'::jsonb);
  assert public.valid_report_warning_lights('[{"code":"S03","color":"red","flashing":true},{"code":"S03","color":"amber","flashing":false}]'::jsonb);
  assert public.valid_report_warning_lights('[{"code":"S10","color":"amber","flashing":false},{"code":"S10","color":"amber","flashing":true}]'::jsonb);
  assert not public.valid_report_warning_lights('[{"code":"S10","color":"amber","flashing":true},{"code":"S10","color":"amber","flashing":true}]'::jsonb);
  assert not public.valid_report_warning_lights('[{"code":"S99","color":"red","flashing":false}]'::jsonb);
  assert not public.valid_report_warning_lights('[{"code":"S03","color":"purple","flashing":false}]'::jsonb);
  assert not public.valid_report_warning_lights('[{"code":"S03","color":"red","flashing":"true"}]'::jsonb);
  assert not public.valid_report_warning_lights('[{"code":"S03"}]'::jsonb);
  assert not public.valid_report_warning_lights('null'::jsonb);
  assert not has_function_privilege('anon','public.get_owner_active_reports()','execute');
  assert not has_function_privilege('anon','public.complete_future_work_report(uuid)','execute');
  assert not has_function_privilege('anon','public.create_future_work_report(uuid,text,date,text,jsonb)','execute');
  assert not has_column_privilege('authenticated','public.future_work_records','vehicle_id','update');
  assert not has_column_privilege('authenticated','public.future_work_records','warning_lights','update');
  assert has_column_privilege('authenticated','public.future_work_records','done','update');
  assert (select relrowsecurity from pg_class where oid='public.future_work_records'::regclass);
end;
$test$;

-- Existing, registered owner fixture; no original row is changed.
do $test$
declare
  v_vehicle uuid; v_owner uuid; v_mechanic_user uuid;
  v_record uuid; v_variant_record uuid; v_records uuid[] := '{}'; v_json jsonb; v_count integer;
begin
  select v.id, v.owner_id into v_vehicle, v_owner
  from public.vehicles v
  where exists (select 1 from public.vehicle_mechanics vm where vm.vehicle_id=v.id)
  limit 1;
  if v_vehicle is null then raise exception 'A linked vehicle fixture is required'; end if;
  select m.user_id into v_mechanic_user
  from public.vehicle_mechanics vm join public.mechanics m on m.id=vm.mechanic_id
  where vm.vehicle_id=v_vehicle and m.is_active limit 1;
  perform set_config('request.jwt.claim.sub', v_owner::text, true);
  execute 'set local role authenticated';
  for n in 1..4 loop
    v_record := public.create_future_work_report(v_vehicle, '', current_date + 1, 'Test computer di bordo', '[{"code":"S03","color":"red","flashing":true}]'::jsonb);
    v_records := array_append(v_records, v_record);
  end loop;
  v_variant_record := public.create_future_work_report(v_vehicle, '', current_date + 1, '', '[{"code":"S10","color":"amber","flashing":false},{"code":"S10","color":"amber","flashing":true}]'::jsonb);
  assert exists (select 1 from jsonb_array_elements(public.get_owner_active_reports()) x where x->>'record_id'=v_variant_record::text and jsonb_array_length(x->'warning_lights')=2 and not (x->'warning_lights'->0->>'flashing')::boolean and (x->'warning_lights'->1->>'flashing')::boolean);
  v_json := public.get_owner_active_reports();
  select count(*) into v_count from jsonb_array_elements(v_json) x where (x->>'record_id')::uuid = any(v_records);
  assert v_count = 4, 'All reports must be returned, including those after position three';
  assert exists (select 1 from jsonb_array_elements(v_json) x where x->>'record_id'=v_record::text and x->>'description'='' and x->>'onboard_message'='Test computer di bordo' and (x->'warning_lights'->0->>'flashing')::boolean);
  perform public.complete_future_work_report(v_record);
  assert not exists (select 1 from jsonb_array_elements(public.get_owner_active_reports()) x where x->>'record_id'=v_record::text);
  perform public.complete_future_work_report(v_record); -- Idempotent retry.
  execute 'reset role';
  assert (select done from public.future_work_records where id=v_record);
  assert (select count(*) from public.future_work_items where record_id=v_record)=1, 'Completion must preserve the record';
  if v_mechanic_user is not null then
    perform set_config('request.jwt.claim.sub', v_mechanic_user::text, true);
    execute 'set local role authenticated';
    v_json := public.get_mechanic_future_work_catalog();
    assert not exists (select 1 from jsonb_array_elements(v_json) v cross join lateral jsonb_array_elements(v->'reports') r where r->>'record_id'=v_record::text);
    assert exists (select 1 from jsonb_array_elements(v_json) v cross join lateral jsonb_array_elements(v->'reports') r where r->>'record_id'=v_records[1]::text and r->>'onboard_message'='Test computer di bordo');
    assert exists (select 1 from jsonb_array_elements(public.get_mechanic_home_catalog()->'vehicles') v where v->>'id'=v_vehicle::text and jsonb_array_length(v->'warning_lights') > 0);
    execute 'reset role';
  end if;
  perform set_config('request.jwt.claim.sub', gen_random_uuid()::text, true);
  execute 'set local role authenticated';
  assert public.get_owner_active_reports()='[]'::jsonb;
  assert public.get_mechanic_future_work_catalog()='[]'::jsonb;
  begin
    perform public.complete_future_work_report(v_records[1]);
    raise exception 'Unrelated user completed a report';
  exception when insufficient_privilege then null;
  end;
  execute 'reset role';
end;
$test$;
rollback;
