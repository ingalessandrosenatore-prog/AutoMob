create type public.mechanic_subscription_plan as enum (
  'none',
  'base',
  'premium',
  'elite'
);

alter table public.mechanic_subscriptions
drop constraint mechanic_subscriptions_plan_code_not_empty;

alter table public.mechanic_subscriptions
alter column plan_code type public.mechanic_subscription_plan
using (
  case lower(btrim(plan_code))
    when 'base' then 'base'
    when 'pro' then 'premium'
    when 'premium' then 'premium'
    when 'top' then 'elite'
    when 'elite' then 'elite'
    else 'none'
  end
)::public.mechanic_subscription_plan;

create or replace function private.get_mechanic_subscription_overview()
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
    'plan_code', coalesce(s.plan_code::text, 'none'),
    'plan_name', case coalesce(s.plan_code::text, 'none')
      when 'base' then 'AutoMob Base'
      when 'premium' then 'AutoMob Premium'
      when 'elite' then 'AutoMob Elite'
      else 'Nessun piano'
    end,
    'status', case
      when m.is_active = false
        or s.mechanic_id is null
        or s.plan_code = 'none'
      then 'inactive'
      when s.status <> 'active' then 'inactive'
      when s.expires_at <= now() then 'expired'
      when s.expires_at <= now() + interval '30 days' then 'expiring'
      else 'active'
    end,
    'expires_at', case
      when s.plan_code is null or s.plan_code = 'none' then null
      else s.expires_at
    end,
    'days_remaining', case
      when s.plan_code is null
        or s.plan_code = 'none'
        or s.expires_at is null
      then 0
      else greatest(s.expires_at::date - current_date, 0)
    end,
    'linked_vehicles', count(distinct vm.vehicle_id)::integer,
    'vehicle_limit', case
      when s.plan_code is null or s.plan_code = 'none' then 0
      else s.vehicle_limit
    end
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

revoke all on function private.get_mechanic_subscription_overview()
from public, anon, authenticated;
grant execute on function private.get_mechanic_subscription_overview()
to authenticated;
