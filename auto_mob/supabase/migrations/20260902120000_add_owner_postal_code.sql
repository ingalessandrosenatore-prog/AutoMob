alter table public.profiles
add column if not exists postal_code text;

alter table public.profiles
drop constraint if exists profiles_postal_code_format;

alter table public.profiles
add constraint profiles_postal_code_format
check (postal_code is null or postal_code ~ '^[0-9]{5}$');

comment on column public.profiles.postal_code is
  'CAP italiano dichiarato dall utente durante la registrazione.';

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

  insert into public.profiles(id, role, full_name, phone, postal_code)
  values (
    new.id,
    v_role,
    v_full_name,
    v_phone,
    nullif(btrim(v_postal_code), '')
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
