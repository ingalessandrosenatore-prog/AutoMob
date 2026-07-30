-- Dati di sviluppo dell'officina Giordano.
-- Prima creare l'utente Auth meccanico dal Dashboard con email
-- meccanico.giordano.test@automob.invalid. Non usiamo un UUID fittizio tutto
-- zero perché la FK mechanics.user_id -> auth.users.id lo rifiuterebbe.
insert into public.mechanics (
  user_id,
  mechanic_code,
  business_name,
  vat_number,
  address,
  is_active
)
select
  id,
  'xxxxxx',
  'Autofficina Gommista GIORDANO',
  'ag123xxx',
  'Via iroma n 101, Nocera Superiore, Italy, 84015',
  true
from auth.users
where email = 'meccanico.giordano.test@automob.invalid'
on conflict (mechanic_code) do update set
  business_name = excluded.business_name,
  vat_number = excluded.vat_number,
  address = excluded.address,
  is_active = excluded.is_active,
  updated_at = now();
