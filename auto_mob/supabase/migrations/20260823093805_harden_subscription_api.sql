drop index if exists public.vehicle_mechanics_mechanic_id_idx;

revoke select on table public.mechanic_subscriptions from authenticated;

create or replace function public.get_mechanic_subscription_overview()
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  result jsonb;
begin
  if auth.uid() is null then
    raise exception 'Utente non autenticato' using errcode = '28000';
  end if;

  select jsonb_build_object(
    'workshop_name', m.business_name,
    'mechanic_code', m.mechanic_code,
    'plan_name', case
      when s.mechanic_id is null then 'Nessun piano'
      when lower(s.plan_code) = 'pro' then 'AutoMob Pro'
      when lower(s.plan_code) = 'base' then 'AutoMob Base'
      else s.plan_code
    end,
    'status', case
      when m.is_active = false or s.mechanic_id is null then 'inactive'
      when s.status <> 'active' then 'inactive'
      when s.expires_at <= now() then 'expired'
      when s.expires_at <= now() + interval '30 days' then 'expiring'
      else 'active'
    end,
    'expires_at', s.expires_at,
    'days_remaining', case
      when s.expires_at is null then 0
      else greatest(s.expires_at::date - current_date, 0)
    end,
    'linked_vehicles', count(distinct vm.vehicle_id)::integer,
    'vehicle_limit', coalesce(s.vehicle_limit, 0)
  )
  into result
  from public.mechanics m
  left join public.mechanic_subscriptions s on s.mechanic_id = m.id
  left join public.vehicle_mechanics vm on vm.mechanic_id = m.id
  where m.user_id = auth.uid()
  group by m.id, s.mechanic_id, s.plan_code, s.status, s.expires_at,
    s.vehicle_limit;

  return result;
end;
$$;

revoke all on function public.get_mechanic_subscription_overview()
from public, anon;
grant execute on function public.get_mechanic_subscription_overview()
to authenticated;
