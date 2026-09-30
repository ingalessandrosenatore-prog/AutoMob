-- Codici officina numerici, verifica protetta e abbonamenti gestiti da admin.
-- Il codice viene assegnato nel trigger Auth: il client non puo sceglierlo.

create or replace function private.mechanic_code_candidate(
  p_mechanic_id uuid,
  p_vat_number text,
  p_attempt integer
)
returns text
language sql
immutable
set search_path = ''
as $$
  select lpad(
    mod(
      abs(
        pg_catalog.hashtextextended(
          p_mechanic_id::text || '|' ||
          upper(regexp_replace(coalesce(p_vat_number, ''), '[^A-Za-z0-9]', '', 'g')),
          p_attempt
        )::numeric
      ),
      1000000
    )::text,
    6,
    '0'
  );
$$;

revoke all on function private.mechanic_code_candidate(uuid, text, integer)
from public, anon, authenticated;

-- Migra i codici esistenti senza usare identificativi hardcoded. Ogni riga ha
-- al massimo 64 candidati: un database quasi saturo fallisce senza loop.
do $$
declare
  mechanic_row record;
  candidate text;
  attempt integer;
  assigned boolean;
begin
  for mechanic_row in
    select id, vat_number from public.mechanics order by id
  loop
    assigned := false;
    for attempt in 0..63 loop
      candidate := private.mechanic_code_candidate(
        mechanic_row.id,
        mechanic_row.vat_number,
        attempt
      );
      begin
        update public.mechanics
        set mechanic_code = candidate
        where id = mechanic_row.id;
        assigned := true;
        exit;
      exception when unique_violation then
        null;
      end;
    end loop;

    if not assigned then
      raise exception 'Impossibile assegnare un codice officina univoco'
        using errcode = 'program_limit_exceeded';
    end if;
  end loop;
end;
$$;

alter table public.mechanics
drop constraint if exists mechanic_code_not_empty;

alter table public.mechanics
add constraint mechanics_mechanic_code_six_digits
check (mechanic_code ~ '^[0-9]{6}$');

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role text := new.raw_user_meta_data ->> 'role';
  v_full_name text := new.raw_user_meta_data ->> 'full_name';
  v_phone text := new.raw_user_meta_data ->> 'phone';
  v_business_name text := new.raw_user_meta_data ->> 'business_name';
  v_vat_number text := new.raw_user_meta_data ->> 'vat_number';
  v_address text := new.raw_user_meta_data ->> 'address';
  v_street_address text := new.raw_user_meta_data ->> 'street_address';
  v_postal_code text := new.raw_user_meta_data ->> 'postal_code';
  v_municipality_istat_code text :=
    new.raw_user_meta_data ->> 'municipality_istat_code';
  v_mechanic_id uuid := gen_random_uuid();
  v_mechanic_code text;
  v_attempt integer;
  v_inserted boolean := false;
begin
  if v_role is null or v_role not in ('proprietario', 'meccanico') then
    raise exception 'Ruolo non valido' using errcode = 'check_violation';
  end if;

  insert into public.profiles(id, role, full_name, phone)
  values (new.id, v_role, v_full_name, v_phone);

  if v_role = 'meccanico' then
    if nullif(btrim(v_business_name), '') is null then
      raise exception 'Ragione sociale meccanico obbligatoria'
        using errcode = 'not_null_violation';
    end if;

    for v_attempt in 0..63 loop
      v_mechanic_code := private.mechanic_code_candidate(
        v_mechanic_id,
        v_vat_number,
        v_attempt
      );
      begin
        insert into public.mechanics(
          id,
          user_id,
          mechanic_code,
          business_name,
          vat_number,
          address,
          street_address,
          postal_code,
          municipality_istat_code,
          number,
          email,
          is_active
        ) values (
          v_mechanic_id,
          new.id,
          v_mechanic_code,
          btrim(v_business_name),
          nullif(btrim(v_vat_number), ''),
          nullif(btrim(v_address), ''),
          nullif(btrim(v_street_address), ''),
          nullif(btrim(v_postal_code), ''),
          nullif(btrim(v_municipality_istat_code), ''),
          nullif(btrim(v_phone), ''),
          new.email,
          false
        );
        v_inserted := true;
        exit;
      exception when unique_violation then
        null;
      end;
    end loop;

    if not v_inserted then
      raise exception 'Impossibile generare un codice officina univoco'
        using errcode = 'program_limit_exceeded';
    end if;
  end if;

  return new;
end;
$$;

revoke all on function public.handle_new_user() from public, anon, authenticated;
grant execute on function public.handle_new_user() to service_role;

create table public.mechanic_subscriptions (
  mechanic_id uuid primary key
    references public.mechanics(id) on delete cascade,
  plan_code text not null,
  status text not null default 'active',
  starts_at timestamptz not null default now(),
  expires_at timestamptz not null,
  vehicle_limit integer not null,
  updated_at timestamptz not null default now(),
  constraint mechanic_subscriptions_plan_code_not_empty
    check (length(btrim(plan_code)) > 0),
  constraint mechanic_subscriptions_status_valid
    check (status in ('active', 'paused', 'cancelled')),
  constraint mechanic_subscriptions_dates_valid
    check (expires_at > starts_at),
  constraint mechanic_subscriptions_vehicle_limit_valid
    check (vehicle_limit >= 0)
);

alter table public.mechanic_subscriptions enable row level security;

create policy mechanic_subscriptions_select_own
on public.mechanic_subscriptions
for select
to authenticated
using (
  exists (
    select 1
    from public.mechanics m
    where m.id = mechanic_id
      and m.user_id = (select auth.uid())
  )
);

revoke all on table public.mechanic_subscriptions from public, anon, authenticated;
grant select on table public.mechanic_subscriptions to authenticated;
grant all on table public.mechanic_subscriptions to service_role;

create or replace function private.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke all on function private.touch_updated_at()
from public, anon, authenticated;

create trigger mechanic_subscriptions_touch_updated_at
before update on public.mechanic_subscriptions
for each row execute function private.touch_updated_at();

create table private.mechanic_code_verification_limits (
  user_id uuid primary key references auth.users(id) on delete cascade,
  window_started_at timestamptz not null,
  attempt_count smallint not null,
  constraint mechanic_code_verification_attempt_count_valid
    check (attempt_count > 0)
);

alter table private.mechanic_code_verification_limits
enable row level security;

revoke all on table private.mechanic_code_verification_limits
from public, anon, authenticated;

create or replace function private.consume_mechanic_code_attempt()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := auth.uid();
  current_attempts smallint;
begin
  if caller_id is null then
    raise exception 'Utente non autenticato' using errcode = '28000';
  end if;

  insert into private.mechanic_code_verification_limits(
    user_id,
    window_started_at,
    attempt_count
  ) values (
    caller_id,
    clock_timestamp(),
    1
  )
  on conflict (user_id) do update
  set window_started_at = case
        when private.mechanic_code_verification_limits.window_started_at
          <= clock_timestamp() - interval '5 minutes'
        then excluded.window_started_at
        else private.mechanic_code_verification_limits.window_started_at
      end,
      attempt_count = case
        when private.mechanic_code_verification_limits.window_started_at
          <= clock_timestamp() - interval '5 minutes'
        then 1
        else private.mechanic_code_verification_limits.attempt_count + 1
      end
  returning attempt_count into current_attempts;

  if current_attempts > 10 then
    raise exception 'Troppe verifiche. Riprova tra cinque minuti.'
      using errcode = 'program_limit_exceeded';
  end if;
end;
$$;

revoke all on function private.consume_mechanic_code_attempt()
from public, anon, authenticated;

create or replace function public.verify_mechanic_code(p_code text)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  normalized_code text := btrim(coalesce(p_code, ''));
  result jsonb;
begin
  if auth.uid() is null then
    raise exception 'Utente non autenticato' using errcode = '28000';
  end if;

  perform private.consume_mechanic_code_attempt();

  if normalized_code !~ '^[0-9]{6}$' then
    return null;
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
  where m.mechanic_code = normalized_code
    and m.is_active = true;

  return result;
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
security definer
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

create or replace function private.is_mechanic_linked_to_current_owner(
  p_mechanic_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null and exists (
    select 1
    from public.vehicle_mechanics vm
    join public.vehicles v on v.id = vm.vehicle_id
    where vm.mechanic_id = p_mechanic_id
      and v.owner_id = auth.uid()
  );
$$;

revoke all on function private.is_mechanic_linked_to_current_owner(uuid)
from public, anon, authenticated;
grant usage on schema private to authenticated;
grant execute on function private.is_mechanic_linked_to_current_owner(uuid)
to authenticated;

drop policy if exists mechanics_select_active_authenticated
on public.mechanics;

create policy mechanics_select_own_or_linked_authenticated
on public.mechanics
for select
to authenticated
using (
  user_id = (select auth.uid())
  or (select private.is_mechanic_linked_to_current_owner(id))
);

create index if not exists vehicle_mechanics_mechanic_id_idx
on public.vehicle_mechanics(mechanic_id);

create or replace function public.get_mechanic_subscription_overview()
returns jsonb
language sql
stable
set search_path = ''
as $$
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
  from public.mechanics m
  left join public.mechanic_subscriptions s on s.mechanic_id = m.id
  left join public.vehicle_mechanics vm on vm.mechanic_id = m.id
  where m.user_id = (select auth.uid())
  group by m.id, s.mechanic_id, s.plan_code, s.status, s.expires_at,
    s.vehicle_limit;
$$;

revoke all on function public.get_mechanic_subscription_overview()
from public, anon;
grant execute on function public.get_mechanic_subscription_overview()
to authenticated;
