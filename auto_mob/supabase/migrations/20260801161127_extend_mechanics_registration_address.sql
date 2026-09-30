-- Prepara la registrazione guidata dell'app meccanico senza interrompere i
-- client esistenti. Le nuove colonne restano nullable durante la migrazione:
-- il wizard le rendera' obbligatorie, poi una migrazione successiva potra'
-- applicare NOT NULL dopo il backfill dei meccanici gia' presenti.
alter table public.mechanics
  add column if not exists street_address text,
  add column if not exists postal_code text,
  add column if not exists municipality_istat_code text;

alter table public.mechanics
  drop constraint if exists mechanics_street_address_format,
  add constraint mechanics_street_address_format
    check (
      street_address is null or nullif(btrim(street_address), '') is not null
    ),
  drop constraint if exists mechanics_postal_code_format,
  add constraint mechanics_postal_code_format
    check (postal_code is null or postal_code ~ '^[0-9]{5}$'),
  drop constraint if exists mechanics_municipality_istat_code_format,
  add constraint mechanics_municipality_istat_code_format
    check (
      municipality_istat_code is null
      or municipality_istat_code ~ '^[0-9]{6}$'
    );

comment on column public.mechanics.street_address is
  'Via e numero civico dell officina.';
comment on column public.mechanics.postal_code is
  'CAP italiano a cinque cifre.';
comment on column public.mechanics.municipality_istat_code is
  'Codice ISTAT a sei cifre del comune selezionato dal dataset ufficiale.';

-- Il trigger continua ad accettare i metadati legacy (address) e salva anche
-- i nuovi campi quando sono inviati dall'app meccanico. I metadati sono usati
-- solo per dati anagrafici, non per decisioni RLS/autorizzative.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_role text := new.raw_user_meta_data ->> 'role';
  v_full_name text := new.raw_user_meta_data ->> 'full_name';
  v_phone text := new.raw_user_meta_data ->> 'phone';
  v_mech_code text := new.raw_user_meta_data ->> 'mechanic_code';
  v_business_name text := new.raw_user_meta_data ->> 'business_name';
  v_vat_number text := new.raw_user_meta_data ->> 'vat_number';
  v_address text := new.raw_user_meta_data ->> 'address';
  v_street_address text := new.raw_user_meta_data ->> 'street_address';
  v_postal_code text := new.raw_user_meta_data ->> 'postal_code';
  v_municipality_istat_code text :=
    new.raw_user_meta_data ->> 'municipality_istat_code';
begin
  if v_role is null or v_role not in ('proprietario', 'meccanico') then
    raise exception 'Ruolo non valido' using errcode = 'check_violation';
  end if;

  insert into public.profiles(id, role, full_name, phone)
  values (new.id, v_role, v_full_name, v_phone);

  if v_role = 'meccanico' then
    if nullif(btrim(v_mech_code), '') is null or
       nullif(btrim(v_business_name), '') is null then
      raise exception 'Codice e ragione sociale meccanico obbligatori'
        using errcode = 'not_null_violation';
    end if;

    insert into public.mechanics(
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
      new.id,
      btrim(v_mech_code),
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
  end if;

  return new;
end;
$function$;

-- E' una trigger function: nessun client deve poterla invocare come RPC.
revoke execute on function public.handle_new_user()
  from public, anon, authenticated;

-- RLS limita le righe, mentre i grant minimi e di colonna impediscono al
-- meccanico di inserire/eliminare officine o modificare user_id,
-- mechanic_code e is_active dalla Data API.
revoke all on table public.mechanics from anon, authenticated;
grant select on table public.mechanics to authenticated;
grant update (
  business_name,
  vat_number,
  address,
  street_address,
  postal_code,
  municipality_istat_code,
  number,
  email
) on table public.mechanics to authenticated;
