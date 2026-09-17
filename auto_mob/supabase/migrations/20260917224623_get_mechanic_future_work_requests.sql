create index if not exists future_work_records_open_feed_idx
on public.future_work_records(created_at desc, id desc, vehicle_id)
where not done;

create or replace function public.get_mechanic_future_work_requests(
  p_cursor_created_at timestamptz default null,
  p_cursor_id uuid default null,
  p_limit integer default 20
)
returns table (
  id uuid,
  vehicle_id uuid,
  vehicle_model text,
  plate text,
  issues text[],
  registered_at timestamptz,
  reminder_date date
)
language sql
stable
security invoker
set search_path = ''
as $$
  with current_mechanic as (
    select m.id
    from public.mechanics m
    where m.user_id = (select auth.uid())
      and m.is_active = true
  ),
  page as (
    select
      fwr.id,
      fwr.vehicle_id,
      concat_ws(' ', nullif(trim(v.brand), ''), nullif(trim(v.model), ''))
        as vehicle_model,
      v.plate,
      fwr.created_at,
      fwr.reminder_date
    from current_mechanic cm
    join public.vehicle_mechanics vm on vm.mechanic_id = cm.id
    join public.future_work_records fwr on fwr.vehicle_id = vm.vehicle_id
    join public.vehicles v on v.id = fwr.vehicle_id
    where not fwr.done
      and (
        p_cursor_created_at is null
        or p_cursor_id is null
        or (fwr.created_at, fwr.id) < (p_cursor_created_at, p_cursor_id)
      )
    order by fwr.created_at desc, fwr.id desc
    limit least(greatest(p_limit, 1), 50)
  )
  select
    page.id,
    page.vehicle_id,
    page.vehicle_model,
    page.plate,
    array_agg(fwi.description order by fwi.created_at, fwi.id) as issues,
    page.created_at as registered_at,
    page.reminder_date
  from page
  join public.future_work_items fwi on fwi.record_id = page.id
  group by
    page.id,
    page.vehicle_id,
    page.vehicle_model,
    page.plate,
    page.created_at,
    page.reminder_date
  order by page.created_at desc, page.id desc;
$$;

revoke all on function public.get_mechanic_future_work_requests(
  timestamptz,
  uuid,
  integer
) from public, anon;
grant execute on function public.get_mechanic_future_work_requests(
  timestamptz,
  uuid,
  integer
) to authenticated;

comment on function public.get_mechanic_future_work_requests(
  timestamptz,
  uuid,
  integer
) is
  'Feed paginato dei lavori futuri aperti dei soli veicoli assegnati al meccanico autenticato.';
