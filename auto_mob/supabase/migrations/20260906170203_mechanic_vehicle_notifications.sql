alter table public.notification_outbox
  drop constraint notification_outbox_category_check;
alter table public.notification_outbox
  add constraint notification_outbox_category_check
  check (category in ('km', 'maintenance_kpi', 'revision', 'mechanic_reminder'));

alter table public.notification_outbox
  add column sender_mechanic_id uuid references public.mechanics(id) on delete set null;

-- Manual reminders use the existing private outbox and unique request key.
-- They are sent immediately by their own endpoint, outside the reminder cron.
alter table public.notification_outbox
  add constraint notification_outbox_mechanic_payload_check check (
    category <> 'mechanic_reminder' or (
      length(btrim(title)) between 1 and 100
      and length(btrim(body)) between 1 and 500
      and coalesce(data->>'intervention_type', '') in (
        'distribuzione', 'tagliando', 'pneumatici_cambio', 'pneumatici_inversione'
      )
    )
  );
