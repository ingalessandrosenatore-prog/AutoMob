alter table public.future_work_records
add column if not exists reminder_date date;

-- Mantiene applicabile la migrazione anche se esistono gia' record creati
-- prima dell'introduzione della data di richiamo.
update public.future_work_records
set reminder_date = created_at::date
where reminder_date is null;

alter table public.future_work_records
alter column reminder_date set not null;

create index if not exists future_work_records_upcoming_idx
on public.future_work_records(vehicle_id, reminder_date, created_at)
where not done;

comment on column public.future_work_records.reminder_date is
  'Data entro cui effettuare i lavori futuri raggruppati nel record.';

create or replace function public.create_future_work_report(
  p_vehicle_id uuid,
  p_description text,
  p_reminder_date date
)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_record_id uuid;
begin
  if (select auth.uid()) is null then
    raise exception 'Utente non autenticato' using errcode = '42501';
  end if;
  if p_description is null
    or length(btrim(p_description)) not between 1 and 1000 then
    raise exception 'Descrizione non valida' using errcode = '22023';
  end if;
  if p_reminder_date is null or p_reminder_date < current_date then
    raise exception 'Data di richiamo non valida' using errcode = '22023';
  end if;

  insert into public.future_work_records (
    vehicle_id,
    created_by_user_id,
    mechanic_id,
    reminder_date
  ) values (
    p_vehicle_id,
    (select auth.uid()),
    null,
    p_reminder_date
  )
  returning id into v_record_id;

  insert into public.future_work_items (record_id, description)
  values (v_record_id, btrim(p_description));

  return v_record_id;
end;
$$;

revoke all on function public.create_future_work_report(uuid, text, date)
from public, anon;
grant execute on function public.create_future_work_report(uuid, text, date)
to authenticated;

comment on function public.create_future_work_report(uuid, text, date) is
  'Crea atomicamente una segnalazione owner e la relativa descrizione.';
