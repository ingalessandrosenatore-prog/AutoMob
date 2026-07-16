-- AutoMob - sistema notifiche push.
--
-- Postgres decide QUALI veicoli devono essere notificati. Le Edge Functions
-- decidono COME inviare il messaggio tramite Firebase Cloud Messaging (FCM).
-- Questa separazione evita di scaricare intere tabelle in JavaScript.

create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;
create extension if not exists supabase_vault with schema vault;

-- Un token FCM identifica una singola installazione dell'app. Un utente puo'
-- quindi avere piu' righe: per esempio telefono e tablet.
create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('android', 'ios')),
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index device_tokens_user_active_idx
  on public.device_tokens(user_id, is_active);

alter table public.device_tokens enable row level security;
revoke all on public.device_tokens from public, anon, authenticated;
grant select, insert, update, delete on public.device_tokens to service_role;

-- Outbox significa "posta in uscita". Prima registriamo qui la notifica,
-- poi il dispatcher prova a consegnarla. La chiave unique rende l'operazione
-- idempotente: due esecuzioni del Cron non creano due notifiche uguali.
create table public.notification_outbox (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  vehicle_id uuid not null references public.vehicles(id) on delete cascade,
  category text not null
    check (category in ('km', 'maintenance_kpi', 'revision')),
  reasons jsonb not null default '[]'::jsonb,
  local_date date not null,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  scheduled_for timestamptz not null,
  status text not null default 'pending'
    check (status in ('pending', 'sent', 'cancelled', 'no_device', 'failed')),
  is_test boolean not null default false,
  deduplication_key text not null unique,
  created_at timestamptz not null default now(),
  sent_at timestamptz,
  last_error text
);

create index notification_outbox_dispatch_idx
  on public.notification_outbox(status, scheduled_for)
  where status = 'pending';
create index notification_outbox_cooldown_idx
  on public.notification_outbox(vehicle_id, category, local_date desc)
  where status = 'sent' and is_test = false;

alter table public.notification_outbox enable row level security;
revoke all on public.notification_outbox from public, anon, authenticated;
grant select, insert, update, delete on public.notification_outbox
  to service_role;

-- Una notifica puo' essere inviata a piu' dispositivi. Questa tabella salva
-- il risultato di ogni singolo tentativo senza nasconderlo in un JSON.
create table public.notification_deliveries (
  id uuid primary key default gen_random_uuid(),
  outbox_id uuid not null
    references public.notification_outbox(id) on delete cascade,
  device_token_id uuid
    references public.device_tokens(id) on delete set null,
  status text not null check (status in ('sent', 'failed')),
  provider_message_id text,
  error_code text,
  attempted_at timestamptz not null default now(),
  unique (outbox_id, device_token_id)
);

alter table public.notification_deliveries enable row level security;
revoke all on public.notification_deliveries from public, anon, authenticated;
grant select, insert, update, delete on public.notification_deliveries
  to service_role;

-- Restituisce soltanto le notifiche candidate per una data italiana.
-- p_as_of rende la funzione testabile: preview puo' simulare una data futura
-- senza cambiare i dati e senza attendere il Cron.
create or replace function public.notification_candidates(
  p_as_of date default ((now() at time zone 'Europe/Rome')::date)
)
returns table (
  user_id uuid,
  vehicle_id uuid,
  category text,
  reasons jsonb,
  scheduled_for timestamptz,
  title text,
  body text,
  deduplication_key text
)
language sql
security invoker
set search_path = ''
as $function$
with
-- Per ogni veicolo leggiamo solo l'ultima riga dello storico grazie
-- all'indice (vehicle_id, created_at desc).
vehicle_status as (
  select
    v.id as vehicle_id,
    v.owner_id,
    v.km_current,
    v.scadenza_revision_date,
    v.tagliando_interval_km,
    v.distribution_intervall_km,
    v.tire_change_interval_km,
    v.tire_rotation_interval_km,
    history.id as last_history_id,
    (history.created_at at time zone 'Europe/Rome')::date
      as last_history_date
  from public.vehicles v
  left join lateral (
    select vh.id, vh.created_at
    from public.vehicle_history vh
    where vh.vehicle_id = v.id
    order by vh.created_at desc
    limit 1
  ) history on true
),
last_sent as (
  select
    o.vehicle_id,
    o.category,
    max(o.local_date) as last_sent_date
  from public.notification_outbox o
  where o.status = 'sent' and o.is_test = false
  group by o.vehicle_id, o.category
),
revision_due as (
  select
    vs.vehicle_id,
    vs.owner_id,
    vs.scadenza_revision_date,
    (vs.scadenza_revision_date - p_as_of) as days_until
  from vehicle_status vs
  where vs.scadenza_revision_date is not null
    and (
      (vs.scadenza_revision_date - p_as_of) in (7, 1)
      or (
        vs.scadenza_revision_date < p_as_of
        and mod(p_as_of - vs.scadenza_revision_date, 2) = 1
      )
    )
),
km_due as (
  select vs.*
  from vehicle_status vs
  left join last_sent sent
    on sent.vehicle_id = vs.vehicle_id and sent.category = 'km'
  where vs.last_history_date is not null
    and p_as_of - vs.last_history_date >= 2
    and (
      sent.last_sent_date is null
      or p_as_of - sent.last_sent_date >= 2
    )
),
-- DISTINCT ON conserva l'intervento con il chilometraggio maggiore per ogni
-- tipo. E' la stessa regola usata dalla dashboard attuale.
latest_maintenance as (
  select distinct on (mr.vehicle_id, mi.type)
    mr.vehicle_id,
    mi.id as maintenance_item_id,
    mi.type,
    mi.service_km,
    mi.service_date
  from public.maintenance_items mi
  join public.maintenance_records mr on mr.id = mi.record_id
  where mi.type in (
    'tagliando',
    'distribuzione',
    'pneumatici_cambio',
    'pneumatici_inversione'
  )
  order by mr.vehicle_id, mi.type, mi.service_km desc, mi.created_at desc
),
maintenance_thresholds as (
  select
    vs.vehicle_id,
    vs.owner_id,
    vs.km_current,
    latest.maintenance_item_id,
    latest.type,
    latest.service_date,
    latest.service_km + case latest.type
      when 'tagliando' then vs.tagliando_interval_km
      when 'distribuzione' then vs.distribution_intervall_km
      when 'pneumatici_cambio' then vs.tire_change_interval_km
      when 'pneumatici_inversione' then vs.tire_rotation_interval_km
    end as due_km
  from vehicle_status vs
  join latest_maintenance latest on latest.vehicle_id = vs.vehicle_id
),
maintenance_crossings as (
  select
    threshold.*,
    crossing.negative_since
  from maintenance_thresholds threshold
  left join lateral (
    select min((vh.created_at at time zone 'Europe/Rome')::date)
      as negative_since
    from public.vehicle_history vh
    where vh.vehicle_id = threshold.vehicle_id
      and vh.km > threshold.due_km
      and (vh.created_at at time zone 'Europe/Rome')::date
        >= threshold.service_date
  ) crossing on true
  where threshold.due_km is not null
    and threshold.km_current > threshold.due_km
),
maintenance_active as (
  select crossing.*
  from maintenance_crossings crossing
  where crossing.negative_since is not null
    and p_as_of - crossing.negative_since >= 2
),
maintenance_due as (
  select
    active.vehicle_id,
    active.owner_id,
    jsonb_agg(
      jsonb_build_object(
        'type', active.type,
        'maintenance_item_id', active.maintenance_item_id,
        'due_km', active.due_km,
        'current_km', active.km_current,
        'negative_since', active.negative_since
      ) order by active.type
    ) as reasons
  from maintenance_active active
  left join last_sent sent
    on sent.vehicle_id = active.vehicle_id
    and sent.category = 'maintenance_kpi'
  where sent.last_sent_date is null
    or p_as_of - sent.last_sent_date >= 2
  group by active.vehicle_id, active.owner_id
),
all_candidates as (
  select
    km.owner_id as user_id,
    km.vehicle_id,
    'km'::text as category,
    jsonb_build_array(jsonb_build_object(
      'type', 'km_stale',
      'last_history_id', km.last_history_id,
      'last_update_date', km.last_history_date
    )) as reasons,
    (
      p_as_of
      + case when revision.vehicle_id is not null
          then time '09:00' else time '18:00' end
    ) at time zone 'Europe/Rome' as scheduled_for,
    'Ogni chilometro racconta una storia'::text as title,
    'Aggiorna AutoMob e prenditi cura della tua auto.'::text as body
  from km_due km
  left join revision_due revision on revision.vehicle_id = km.vehicle_id

  union all

  select
    maintenance.owner_id,
    maintenance.vehicle_id,
    'maintenance_kpi'::text,
    maintenance.reasons,
    (p_as_of + time '13:00') at time zone 'Europe/Rome',
    'La tua auto merita attenzione'::text,
    'Apri AutoMob e controlla come prendertene cura.'::text
  from maintenance_due maintenance

  union all

  select
    revision.owner_id,
    revision.vehicle_id,
    'revision'::text,
    jsonb_build_array(jsonb_build_object(
      'type', 'revision',
      'due_date', revision.scadenza_revision_date,
      'days_until', revision.days_until
    )),
    (p_as_of + time '18:00') at time zone 'Europe/Rome',
    'E'' il momento di controllare la revisione'::text,
    'Apri AutoMob e assicurati di circolare sempre in regola.'::text
  from revision_due revision
)
select
  candidate.user_id,
  candidate.vehicle_id,
  candidate.category,
  candidate.reasons,
  candidate.scheduled_for,
  candidate.title,
  candidate.body,
  concat(
    candidate.vehicle_id,
    ':', candidate.category,
    ':', p_as_of
  ) as deduplication_key
from all_candidates candidate;
$function$;

revoke all on function public.notification_candidates(date)
  from public, anon, authenticated;
grant execute on function public.notification_candidates(date)
  to service_role;

-- Configurazione privata usata per autenticare le chiamate del Cron.
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to service_role;

create table private.notification_system_config (
  id boolean primary key default true check (id = true),
  cron_secret_hash text not null
);

alter table private.notification_system_config enable row level security;
revoke all on private.notification_system_config
  from public, anon, authenticated;
grant select on private.notification_system_config to service_role;

-- Generiamo il segreto una volta sola. Vault conserva il valore leggibile dal
-- job; la tabella privata conserva soltanto SHA-256 per la verifica.
do $block$
declare
  generated_secret text;
begin
  if not exists (
    select 1 from vault.secrets where name = 'notification_cron_secret'
  ) then
    generated_secret := encode(gen_random_bytes(32), 'hex');
    perform vault.create_secret(
      generated_secret,
      'notification_cron_secret',
      'Autentica il Cron delle notifiche AutoMob'
    );
    insert into private.notification_system_config(id, cron_secret_hash)
    values (true, encode(digest(generated_secret, 'sha256'), 'hex'))
    on conflict (id) do update
      set cron_secret_hash = excluded.cron_secret_hash;
  end if;

  if not exists (
    select 1 from vault.secrets where name = 'notification_project_url'
  ) then
    perform vault.create_secret(
      'https://tvxcyjqaiyxmmhktwhdb.supabase.co',
      'notification_project_url',
      'URL progetto usato dal Cron notifiche AutoMob'
    );
  end if;
end;
$block$;

create or replace function public.verify_notification_cron_secret(
  p_secret text
)
returns boolean
language sql
security invoker
set search_path = ''
as $function$
  select exists (
    select 1
    from private.notification_system_config config
    where config.id = true
      and config.cron_secret_hash = encode(
        extensions.digest(coalesce(p_secret, ''), 'sha256'),
        'hex'
      )
  );
$function$;

revoke all on function public.verify_notification_cron_secret(text)
  from public, anon, authenticated;
grant execute on function public.verify_notification_cron_secret(text)
  to service_role;

-- Gli indici rendono economiche le ricerche "ultima riga per veicolo".
create index if not exists vehicle_history_vehicle_created_idx
  on public.vehicle_history(vehicle_id, created_at desc);
create index if not exists maintenance_records_vehicle_idx
  on public.maintenance_records(vehicle_id);
create index if not exists maintenance_items_record_type_km_idx
  on public.maintenance_items(record_id, type, service_km desc);

-- Crea un job HTTP. Due orari UTC coprono ora solare e legale; la Edge
-- Function esegue davvero l'azione soltanto quando l'ora Europe/Rome coincide.
create or replace function private.schedule_notification_job(
  p_name text,
  p_schedule text,
  p_body jsonb
)
returns bigint
language plpgsql
security invoker
set search_path = ''
as $function$
declare
  job_id bigint;
  command text;
begin
  command := format($command$
    select net.http_post(
      url := (
        select decrypted_secret
        from vault.decrypted_secrets
        where name = 'notification_project_url'
      ) || '/functions/v1/notification-dispatch',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'x-cron-secret', (
          select decrypted_secret
          from vault.decrypted_secrets
          where name = 'notification_cron_secret'
        )
      ),
      body := %L::jsonb
    );
  $command$, p_body::text);

  select cron.schedule(p_name, p_schedule, command) into job_id;
  return job_id;
end;
$function$;

revoke all on function private.schedule_notification_job(text, text, jsonb)
  from public, anon, authenticated;

-- Valutazione alle 07:00 italiane.
select private.schedule_notification_job(
  'automob-notifications-evaluate-summer', '0 5 * * *',
  '{"action":"evaluate","expected_local_time":"07:00"}'::jsonb
);
select private.schedule_notification_job(
  'automob-notifications-evaluate-winter', '0 6 * * *',
  '{"action":"evaluate","expected_local_time":"07:00"}'::jsonb
);

-- Invio km mattutino quando la revisione occupa lo slot serale.
select private.schedule_notification_job(
  'automob-notifications-0900-summer', '0 7 * * *',
  '{"action":"dispatch","slot":"09:00","expected_local_time":"09:00"}'::jsonb
);
select private.schedule_notification_job(
  'automob-notifications-0900-winter', '0 8 * * *',
  '{"action":"dispatch","slot":"09:00","expected_local_time":"09:00"}'::jsonb
);

-- KPI manutenzione alle 13:00.
select private.schedule_notification_job(
  'automob-notifications-1300-summer', '0 11 * * *',
  '{"action":"dispatch","slot":"13:00","expected_local_time":"13:00"}'::jsonb
);
select private.schedule_notification_job(
  'automob-notifications-1300-winter', '0 12 * * *',
  '{"action":"dispatch","slot":"13:00","expected_local_time":"13:00"}'::jsonb
);

-- Revisione prioritaria, oppure km, alle 18:00.
select private.schedule_notification_job(
  'automob-notifications-1800-summer', '0 16 * * *',
  '{"action":"dispatch","slot":"18:00","expected_local_time":"18:00"}'::jsonb
);
select private.schedule_notification_job(
  'automob-notifications-1800-winter', '0 17 * * *',
  '{"action":"dispatch","slot":"18:00","expected_local_time":"18:00"}'::jsonb
);
