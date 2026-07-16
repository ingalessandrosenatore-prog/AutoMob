-- Firebase client, token dispositivo e service account FCM sono stati
-- verificati con invii reali. Da questo momento i job possono lavorare.
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
      active := true
    );
  end loop;
end;
$$;
