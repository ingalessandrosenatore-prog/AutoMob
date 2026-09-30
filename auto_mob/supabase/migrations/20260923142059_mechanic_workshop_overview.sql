create or replace function public.get_mechanic_workshop_overview(
  p_reference_date date default current_date
)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with mechanic_records as (
    select mr.id, mr.service_date
    from public.maintenance_records mr
    join public.mechanics m on m.id = mr.mechanic_id
    where m.user_id = (select auth.uid())
      and m.is_active
      and mr.service_date >= date_trunc('year', p_reference_date)::date
      and mr.service_date < (date_trunc('year', p_reference_date) + interval '1 year')::date
  ), record_revenue as (
    -- Aggregate parts before counting records so a multi-item job remains one job.
    select
      mr.id,
      mr.service_date,
      coalesce(round(sum(mip.quantity * mip.unit_price) * 100), 0)::bigint
        as revenue_cents
    from mechanic_records mr
    left join public.maintenance_items mi on mi.record_id = mr.id
    left join public.maintenance_item_parts mip
      on mip.item_id = mi.id
      and mip.unit_price is not null
    group by mr.id, mr.service_date
  ), totals as (
    select
      count(*) filter (where service_date = p_reference_date)::integer as day_jobs,
      coalesce(sum(revenue_cents) filter (where service_date = p_reference_date), 0)::bigint
        as day_revenue_cents,
      count(*) filter (
        where service_date >= date_trunc('month', p_reference_date)::date
          and service_date < (date_trunc('month', p_reference_date) + interval '1 month')::date
      )::integer as month_jobs,
      coalesce(sum(revenue_cents) filter (
        where service_date >= date_trunc('month', p_reference_date)::date
          and service_date < (date_trunc('month', p_reference_date) + interval '1 month')::date
      ), 0)::bigint as month_revenue_cents,
      count(*)::integer as year_jobs,
      coalesce(sum(revenue_cents), 0)::bigint as year_revenue_cents
    from record_revenue
  ), available as (
    -- Match the service-request feed: one available job per vehicle with open reports.
    select count(distinct r.vehicle_id)::integer as jobs
    from public.future_work_records r
    where not r.done
      and exists (
        select 1
        from public.vehicle_mechanics vm
        join public.mechanics m on m.id = vm.mechanic_id
        where vm.vehicle_id = r.vehicle_id
          and m.user_id = (select auth.uid())
          and m.is_active
      )
  )
  select jsonb_build_object(
    'available_jobs', available.jobs,
    'periods', jsonb_build_object(
      'day', jsonb_build_object(
        'completed_jobs', totals.day_jobs,
        'revenue_cents', totals.day_revenue_cents
      ),
      'month', jsonb_build_object(
        'completed_jobs', totals.month_jobs,
        'revenue_cents', totals.month_revenue_cents
      ),
      'year', jsonb_build_object(
        'completed_jobs', totals.year_jobs,
        'revenue_cents', totals.year_revenue_cents
      )
    )
  )
  from totals
  cross join available;
$$;

revoke all on function public.get_mechanic_workshop_overview(date)
from public, anon;
grant execute on function public.get_mechanic_workshop_overview(date)
to authenticated;

comment on function public.get_mechanic_workshop_overview(date) is
  'KPI aggregate dell officina autenticata per giorno, mese e anno.';

notify pgrst, 'reload schema';
