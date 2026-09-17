begin;

do $test$
begin
  if not exists (
    select 1 from pg_class
    where oid = 'public.future_work_records'::regclass
      and relrowsecurity
  ) then
    raise exception 'future_work_records must have RLS enabled';
  end if;

  if not exists (
    select 1 from pg_class
    where oid = 'public.future_work_items'::regclass
      and relrowsecurity
  ) then
    raise exception 'future_work_items must have RLS enabled';
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'future_work_records'
      and column_name = 'done'
      and data_type = 'boolean'
      and is_nullable = 'NO'
      and column_default = 'false'
  ) then
    raise exception 'future_work_records.done contract is missing';
  end if;

  if not exists (
    select 1 from information_schema.columns
    where table_schema = 'public'
      and table_name = 'future_work_records'
      and column_name = 'reminder_date'
      and data_type = 'date'
      and is_nullable = 'NO'
  ) then
    raise exception 'future_work_records.reminder_date contract is missing';
  end if;

  if not exists (
    select 1 from information_schema.table_constraints tc
    join information_schema.constraint_column_usage ccu
      on ccu.constraint_name = tc.constraint_name
      and ccu.constraint_schema = tc.constraint_schema
    where tc.table_schema = 'public'
      and tc.table_name = 'future_work_items'
      and tc.constraint_type = 'FOREIGN KEY'
      and ccu.table_schema = 'public'
      and ccu.table_name = 'future_work_records'
  ) then
    raise exception 'future_work_items must reference future_work_records';
  end if;

  if has_table_privilege('anon', 'public.future_work_records', 'select')
    or has_table_privilege('anon', 'public.future_work_items', 'select') then
    raise exception 'future work tables are exposed to anon';
  end if;

  if not has_column_privilege(
    'authenticated', 'public.future_work_records', 'done', 'update'
  ) then
    raise exception 'authenticated role cannot complete a future work record';
  end if;

  if has_column_privilege(
    'authenticated', 'public.future_work_records', 'vehicle_id', 'update'
  ) then
    raise exception 'authenticated role can move a future work record';
  end if;

  if to_regprocedure(
    'public.create_future_work_report(uuid,text,date)'
  ) is null then
    raise exception 'create_future_work_report contract is missing';
  end if;

  if has_function_privilege(
    'anon',
    'public.create_future_work_report(uuid,text,date)',
    'execute'
  ) then
    raise exception 'anon must not execute create_future_work_report';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.create_future_work_report(uuid,text,date)',
    'execute'
  ) then
    raise exception 'authenticated must execute create_future_work_report';
  end if;

  if to_regprocedure(
    'public.get_owner_dashboard_future_works()'
  ) is null then
    raise exception 'get_owner_dashboard_future_works contract is missing';
  end if;

  if has_function_privilege(
    'anon',
    'public.get_owner_dashboard_future_works()',
    'execute'
  ) then
    raise exception 'anon must not execute get_owner_dashboard_future_works';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.get_owner_dashboard_future_works()',
    'execute'
  ) then
    raise exception 'authenticated must execute dashboard future works RPC';
  end if;

  if to_regprocedure(
    'public.get_mechanic_future_work_requests(timestamp with time zone,uuid,integer)'
  ) is null then
    raise exception 'get_mechanic_future_work_requests contract is missing';
  end if;

  if has_function_privilege(
    'anon',
    'public.get_mechanic_future_work_requests(timestamp with time zone,uuid,integer)',
    'execute'
  ) then
    raise exception 'anon must not execute mechanic future work requests RPC';
  end if;

  if not has_function_privilege(
    'authenticated',
    'public.get_mechanic_future_work_requests(timestamp with time zone,uuid,integer)',
    'execute'
  ) then
    raise exception 'authenticated must execute mechanic future works RPC';
  end if;
end;
$test$;

rollback;
