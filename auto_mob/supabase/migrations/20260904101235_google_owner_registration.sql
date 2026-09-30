-- Only newly provisioned Google accounts require this onboarding gate.
-- Existing email owners keep their current access, even if older profiles lack CAP.
alter table public.profiles add column owner_onboarding_required boolean not null default false;

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role text := new.raw_user_meta_data ->> 'role';
  v_full_name text := coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name');
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
  -- Provider metadata is controlled by Auth. Google only provisions owners.
  if new.raw_app_meta_data ->> 'provider' = 'google' then
    v_role := 'proprietario';
    v_phone := null;
    v_postal_code := null;
  end if;
  if v_role is null or v_role not in ('proprietario', 'meccanico') then
    raise exception 'Ruolo non valido' using errcode = 'check_violation';
  end if;

  insert into public.profiles(id, role, full_name, phone, postal_code, owner_onboarding_required)
  values (
    new.id,
    v_role,
    v_full_name,
    v_phone,
    nullif(btrim(v_postal_code), ''),
    coalesce(new.raw_app_meta_data ->> 'provider' = 'google', false)
  );

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

-- Authenticated users may edit contact information, never their authorization
-- or the server-owned onboarding gate. Existing service workflows remain valid.
create or replace function private.protect_profile_access()
returns trigger language plpgsql set search_path = '' as $$
begin
  if current_user in ('authenticated', 'anon') and
    (new.id is distinct from old.id or new.role is distinct from old.role or
     new.owner_onboarding_required is distinct from old.owner_onboarding_required) then
    raise exception 'Profile access fields are server managed' using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke all on function private.protect_profile_access() from public, anon, authenticated;
create trigger protect_profile_access before update on public.profiles
for each row execute function private.protect_profile_access();

create or replace function public.resolve_owner_registration(
  p_user_id uuid, p_full_name text default null, p_phone text default null,
  p_postal_code text default null, p_complete boolean default false
)
returns jsonb language plpgsql security invoker set search_path = '' as $$
declare
  p public.profiles%rowtype;
begin
  -- Only service_role can invoke this RPC; the Edge Function verifies the JWT
  -- and supplies its subject. Row locking makes retries/concurrent callbacks safe.
  select * into p from public.profiles where id = p_user_id for update;
  if not found then return jsonb_build_object('status', 'missing'); end if;
  if p.role is distinct from 'proprietario' then
    return jsonb_build_object('status', 'forbidden');
  end if;
  if p_complete and p.owner_onboarding_required then
    if nullif(btrim(p_full_name), '') is null or length(btrim(p_full_name)) > 150 or
      p_phone is null or btrim(p_phone) !~ '^\+?[0-9 ()-]{8,30}$' or
      length(regexp_replace(p_phone, '[^0-9]', '', 'g')) not between 8 and 15 or
      p_postal_code is null or btrim(p_postal_code) !~ '^[0-9]{5}$' then
      raise exception 'Invalid owner profile' using errcode = '22023';
    end if;
    update public.profiles set full_name = btrim(p_full_name), phone = btrim(p_phone),
      postal_code = btrim(p_postal_code), owner_onboarding_required = false
      where id = p_user_id returning * into p;
  end if;
  return jsonb_build_object('status', case when p.owner_onboarding_required then 'incomplete' else 'ready' end,
    'profile', jsonb_build_object('full_name', p.full_name, 'phone', p.phone, 'postal_code', p.postal_code));
end;
$$;
revoke all on function public.resolve_owner_registration(uuid, text, text, text, boolean) from public, anon, authenticated;
grant execute on function public.resolve_owner_registration(uuid, text, text, text, boolean) to service_role;

-- The function reads only the caller's gate and avoids RLS recursion.
create or replace function private.owner_registration_ready()
returns boolean language sql stable security definer set search_path = '' as $$
  select not exists (select 1 from public.profiles
    where id = (select auth.uid()) and owner_onboarding_required);
$$;
revoke all on function private.owner_registration_ready() from public, anon;
grant execute on function private.owner_registration_ready() to authenticated;

do $$
declare t text;
begin
  foreach t in array array['vehicles', 'vehicle_mechanics', 'maintenance_records',
    'maintenance_items', 'maintenance_item_parts', 'vehicle_history',
    'vehicle_lookup_results', 'vehicle_external_snapshots'] loop
    execute format('create policy owner_registration_gate on public.%I as restrictive for all to authenticated using ((select private.owner_registration_ready())) with check ((select private.owner_registration_ready()))', t);
  end loop;
end;
$$;

-- Business RPCs can be SECURITY DEFINER. Guard their writes as well as RLS.
create or replace function private.require_owner_registration()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if not private.owner_registration_ready() then
    raise exception 'Complete owner registration first' using errcode = '42501';
  end if;
  return new;
end;
$$;
revoke all on function private.require_owner_registration() from public, anon, authenticated;
do $$
declare t text;
begin
  foreach t in array array['vehicles', 'vehicle_mechanics', 'maintenance_records',
    'maintenance_items', 'maintenance_item_parts', 'vehicle_history'] loop
    execute format('create trigger require_owner_registration before insert or update on public.%I for each row execute function private.require_owner_registration()', t);
  end loop;
end;
$$;
