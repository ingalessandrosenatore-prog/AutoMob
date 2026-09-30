create or replace function public.get_mechanic_future_work_catalog()
returns jsonb
language sql stable security invoker
set search_path = ''
as $$
  with vehicle_requests as (
    select
      v.id as vehicle_id,
      concat_ws(' ', nullif(trim(v.brand), ''), nullif(trim(v.model), '')) as vehicle_model,
      v.plate,
      max(r.created_at) as registered_at,
      min(r.reminder_date) as reminder_date,
      coalesce(
        jsonb_agg(i.description order by r.created_at desc, r.id desc, i.created_at, i.id)
          filter (where i.id is not null),
        '[]'::jsonb
      ) as issues
    from public.future_work_records r
    join public.vehicles v on v.id = r.vehicle_id
    left join public.future_work_items i on i.record_id = r.id
    where not r.done
      and exists (
        select 1 from public.vehicle_mechanics vm
        join public.mechanics m on m.id = vm.mechanic_id
        where vm.vehicle_id = r.vehicle_id
          and m.user_id = (select auth.uid())
          and m.is_active
      )
    group by v.id, v.brand, v.model, v.plate
  )
  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'id', vehicle_id,
        'vehicle_id', vehicle_id,
        'vehicle_model', vehicle_model,
        'plate', plate,
        'registered_at', registered_at,
        'reminder_date', reminder_date,
        'issues', issues
      ) order by registered_at desc, vehicle_id desc
    ),
    '[]'::jsonb
  )
  from vehicle_requests;
$$;

revoke all on function public.get_mechanic_future_work_catalog() from public, anon;
grant execute on function public.get_mechanic_future_work_catalog() to authenticated;
notify pgrst, 'reload schema';
