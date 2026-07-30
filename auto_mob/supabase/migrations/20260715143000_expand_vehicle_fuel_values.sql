-- La UI consente anche veicoli a idrogeno. Le varianti ibride, GPL e metano
-- vengono normalizzate dal data layer prima del salvataggio.
alter table public.vehicles drop constraint if exists fuel_valid;
alter table public.vehicles
  add constraint fuel_valid check (
    fuel = any (array[
      'benzina'::text,
      'diesel'::text,
      'gpl'::text,
      'metano'::text,
      'elettrico'::text,
      'ibrido'::text,
      'idrogeno'::text
    ])
  ) not valid;
alter table public.vehicles validate constraint fuel_valid;
