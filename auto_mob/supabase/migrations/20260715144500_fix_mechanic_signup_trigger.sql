-- Il trigger precedente scriveva la colonna inesistente subscription_status e
-- impediva qualsiasi signup meccanico. L'abbonamento verrà modellato nella
-- sessione dedicata; per ora il nuovo meccanico nasce non attivo.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_role text := new.raw_user_meta_data ->> 'role';
  v_full_name text := new.raw_user_meta_data ->> 'full_name';
  v_phone text := new.raw_user_meta_data ->> 'phone';
  v_mech_code text := new.raw_user_meta_data ->> 'mechanic_code';
  v_business_name text := new.raw_user_meta_data ->> 'business_name';
  v_vat_number text := new.raw_user_meta_data ->> 'vat_number';
  v_address text := new.raw_user_meta_data ->> 'address';
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
      user_id, mechanic_code, business_name, vat_number, address, is_active
    ) values (
      new.id, btrim(v_mech_code), btrim(v_business_name),
      v_vat_number, v_address, false
    );
  end if;
  return new;
end;
$function$;

-- È una trigger function: nessun client deve poterla invocare come RPC.
revoke execute on function public.handle_new_user() from public, anon, authenticated;
