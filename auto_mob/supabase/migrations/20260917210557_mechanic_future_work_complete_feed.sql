create or replace function public.get_mechanic_future_work_catalog()
returns jsonb
language sql stable security invoker
set search_path = ''
as $$
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', r.id,
      'vehicle_id', r.vehicle_id,
      'vehicle_model', concat_ws(' ', nullif(trim(v.brand), ''), nullif(trim(v.model), '')),
      'plate', v.plate,
      'registered_at', r.created_at,
      'reminder_date', r.reminder_date,
      'issues', (
        select coalesce(jsonb_agg(i.description order by i.created_at, i.id), '[]'::jsonb)
        from public.future_work_items i where i.record_id = r.id
      )
    ) order by r.created_at desc, r.id desc
  ), '[]'::jsonb)
  from public.future_work_records r
  join public.vehicles v on v.id = r.vehicle_id
  where not r.done
    and exists (
      select 1 from public.vehicle_mechanics vm
      join public.mechanics m on m.id = vm.mechanic_id
      where vm.vehicle_id = r.vehicle_id
        and m.user_id = (select auth.uid())
        and m.is_active
    );
$$;
revoke all on function public.get_mechanic_future_work_catalog() from public, anon;
grant execute on function public.get_mechanic_future_work_catalog() to authenticated;
notify pgrst, 'reload schema';
