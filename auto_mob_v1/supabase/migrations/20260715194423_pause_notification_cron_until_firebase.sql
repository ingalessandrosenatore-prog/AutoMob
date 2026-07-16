-- Le funzioni e gli orari sono gia pronti, ma l'invio FCM richiede ancora
-- FIREBASE_SERVICE_ACCOUNT_JSON. Teniamo quindi i job disattivati finche la
-- configurazione Firebase non e completa: evitiamo errori e righe pendenti.
do $$
declare
  notification_job record;
begin
  for notification_job in
    select jobid
    from cron.job
    where jobname like 'automob-notifications-%'
  loop
    perform cron.alter_job(
      job_id := notification_job.jobid,
      active := false
    );
  end loop;
end;
$$;
