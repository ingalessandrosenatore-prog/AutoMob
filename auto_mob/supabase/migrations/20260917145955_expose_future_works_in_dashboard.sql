create or replace function public.get_owner_dashboard_future_works()
returns table (
  id uuid,
  record_id uuid,
  vehicle_id uuid,
  description text,
  registered_at timestamptz,
  reminder_date date
)
language sql
stable
security invoker
set search_path = ''
as $$
  select
    ranked.id,
    ranked.record_id,
    ranked.vehicle_id,
    ranked.description,
    ranked.registered_at,
    ranked.reminder_date
  from (
    select
      fwi.id,
      fwr.id as record_id,
      fwr.vehicle_id,
      fwi.description,
      fwr.created_at as registered_at,
      fwr.reminder_date,
      row_number() over (
        partition by fwr.vehicle_id
        order by fwr.created_at desc, fwi.created_at desc, fwi.id desc
      ) as position
    from public.future_work_records as fwr
    join public.future_work_items as fwi on fwi.record_id = fwr.id
    where fwr.done = false
  ) as ranked
  where ranked.position <= 3
  order by ranked.vehicle_id, ranked.registered_at desc, ranked.id desc;
$$;

revoke all on function public.get_owner_dashboard_future_works()
from public, anon;
grant execute on function public.get_owner_dashboard_future_works()
to authenticated;

comment on function public.get_owner_dashboard_future_works() is
  'Restituisce al massimo tre voci future aperte per ogni veicolo accessibile.';
