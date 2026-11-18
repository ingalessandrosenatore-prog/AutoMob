-- Uses an existing owner to exercise RLS. The fixture and all writes roll back.
begin;
do $test$
declare
  owner_id uuid;
  vehicle_id uuid;
  prior_km integer := 16000;
  service_km integer := 20000;
  work_id uuid;
begin
  select v.owner_id into strict owner_id from public.vehicles v limit 1;
  assert not has_function_privilege('anon', 'public.vehicle_component_maintenance_status(uuid[])', 'execute');

  perform set_config('request.jwt.claim.sub', owner_id::text, true);
  execute 'set local role authenticated';
  vehicle_id := public.crea_veicolo_con_manutenzione_componenti(
    jsonb_build_object(
      'veicolo', jsonb_build_object(
        'plate', 'ZZ394XY', 'brand', 'Test', 'model', 'Componenti',
        'year', 2020, 'fuel', 'benzina', 'km_current', service_km
      ),
      'brake_inspection_date', current_date - 3,
      'maintenance_components', jsonb_build_array(
        jsonb_build_object('part_id', 15, 'work_type', 'tagliando',
          'interval_km', 15000, 'initial_km', prior_km),
        jsonb_build_object('part_id', 16, 'work_type', 'tagliando',
          'interval_km', 15000, 'initial_km', prior_km),
        jsonb_build_object('part_id', 20, 'work_type', 'freni',
          'interval_km', 40000, 'initial_km', prior_km)
      )
    )
  );
  assert (select v.brake_inspection_date = current_date - 3
    from public.vehicles v where v.id = vehicle_id);
  assert (select count(*) = 2 from public.get_work_log_parts(vehicle_id)
    where work_type = 'tagliando');

  work_id := public.crea_sessione_manutenzione(jsonb_build_object(
    'vehicle_id', vehicle_id, 'type', 'tagliando', 'service_km', service_km,
    'service_date', current_date, 'parts', '[{"part_id":16},{"part_id":20}]'::jsonb
  ));
  assert work_id is not null;
  assert (select last_service_km = prior_km
    from public.vehicle_component_maintenance_status(array[vehicle_id]) where part_id = 15);
  assert (select last_service_km = service_km
    from public.vehicle_component_maintenance_status(array[vehicle_id]) where part_id = 16);
  assert (select last_service_km = service_km
    from public.vehicle_component_maintenance_status(array[vehicle_id]) where part_id = 20);

  perform set_config('request.jwt.claim.sub', gen_random_uuid()::text, true);
  assert not exists (select from public.vehicle_component_maintenance_status(array[vehicle_id]));
  assert not exists (select from public.get_work_log_parts(vehicle_id) where work_type is not null);
  execute 'reset role';
end;
$test$;
rollback;
