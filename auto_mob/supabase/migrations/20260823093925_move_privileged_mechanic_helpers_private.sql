create or replace function private.lookup_active_mechanic_by_code(p_code text)
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
    'id', m.id,
    'mechanic_code', m.mechanic_code,
    'business_name', m.business_name,
    'address', m.address,
    'number', m.number,
    'email', m.email
  )
  into result
  from public.mechanics m
  where m.mechanic_code = p_code
    and m.is_active = true;

  return result;
end;
$$;

revoke all on function private.lookup_active_mechanic_by_code(text)
from public, anon, authenticated;
grant execute on function private.lookup_active_mechanic_by_code(text)
to authenticated;
grant execute on function private.consume_mechanic_code_attempt()
to authenticated;

create or replace function public.verify_mechanic_code(p_code text)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  normalized_code text := btrim(coalesce(p_code, ''));
begin
  if auth.uid() is null then
    raise exception 'Utente non autenticato' using errcode = '28000';
  end if;

  perform private.consume_mechanic_code_attempt();

  if normalized_code !~ '^[0-9]{6}$' then
    return null;
  end if;

  return private.lookup_active_mechanic_by_code(normalized_code);
end;
$$;

revoke all on function public.verify_mechanic_code(text)
from public, anon;
grant execute on function public.verify_mechanic_code(text) to authenticated;

create or replace function public.connect_vehicle_to_mechanic_by_code(
  p_vehicle_id uuid,
  p_code text
)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  mechanic jsonb;
begin
  if caller_id is null then
    raise exception 'Utente non autenticato' using errcode = '28000';
  end if;

  if not exists (
    select 1
    from public.vehicles v
    where v.id = p_vehicle_id
      and v.owner_id = caller_id
  ) then
    raise exception 'Veicolo non appartenente all utente'
      using errcode = 'insufficient_privilege';
  end if;

  mechanic := public.verify_mechanic_code(p_code);
  if mechanic is null then
    raise exception 'Codice meccanico non valido o officina non attiva'
      using errcode = 'invalid_parameter_value';
  end if;

  insert into public.vehicle_mechanics(vehicle_id, mechanic_id)
  values (p_vehicle_id, (mechanic ->> 'id')::uuid);

  return mechanic;
end;
$$;

revoke all on function public.connect_vehicle_to_mechanic_by_code(uuid, text)
from public, anon;
grant execute on function public.connect_vehicle_to_mechanic_by_code(uuid, text)
to authenticated;

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

revoke all on function private.get_mechanic_subscription_overview()
from public, anon, authenticated;
grant execute on function private.get_mechanic_subscription_overview()
to authenticated;

create or replace function public.get_mechanic_subscription_overview()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select private.get_mechanic_subscription_overview();
$$;

revoke all on function public.get_mechanic_subscription_overview()
from public, anon;
grant execute on function public.get_mechanic_subscription_overview()
to authenticated;
