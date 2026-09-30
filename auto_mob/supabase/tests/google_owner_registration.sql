-- Run inside a transaction; fixtures and all writes are rolled back.
begin;

do $test$
declare u uuid := gen_random_uuid(); m uuid := gen_random_uuid(); r jsonb;
begin
 insert into auth.users(id,email,raw_app_meta_data,raw_user_meta_data)
 values(u,'oauth-test-'||u||'@example.invalid','{"provider":"google"}','{"name":"Google Test","role":"meccanico"}');
 if not exists(select 1 from public.profiles where id=u and role='proprietario' and owner_onboarding_required and full_name='Google Test')
 then raise exception 'Google provisioning failed'; end if;
 perform set_config('request.jwt.claim.sub',u::text,true);
 if private.owner_registration_ready() then raise exception 'Pending account passed gate'; end if;
 r := public.resolve_owner_registration(u);
 if r->>'status' <> 'incomplete' then raise exception 'Expected incomplete'; end if;
 begin
  perform public.resolve_owner_registration(u,'Test','abc','00100',true);
  raise exception 'Invalid contact accepted';
 exception when invalid_parameter_value then null;
 end;
 r := public.resolve_owner_registration(u,'Completed Name','3331234567','00100',true);
 if r->>'status' <> 'ready' then raise exception 'Completion failed'; end if;
 r := public.resolve_owner_registration(u,'Overwrite Attempt','3339999999','99999',true);
 if r#>>'{profile,full_name}' <> 'Completed Name' then raise exception 'Retry overwrote profile'; end if;
 if not private.owner_registration_ready() then raise exception 'Completed account blocked'; end if;
 insert into auth.users(id,email,raw_app_meta_data,raw_user_meta_data)
 values(m,'manual-test-'||m||'@example.invalid','{"provider":"email"}','{"role":"meccanico","full_name":"Manual Test","business_name":"Workshop Test"}');
 if not exists(select 1 from public.mechanics where user_id=m) then raise exception 'Manual mechanic regression'; end if;
 if public.resolve_owner_registration(m)->>'status' <> 'forbidden' then raise exception 'Mechanic admitted'; end if;
 if has_function_privilege('authenticated','public.resolve_owner_registration(uuid,text,text,text,boolean)','execute')
 then raise exception 'RPC exposed'; end if;
end;
$test$;
rollback;
