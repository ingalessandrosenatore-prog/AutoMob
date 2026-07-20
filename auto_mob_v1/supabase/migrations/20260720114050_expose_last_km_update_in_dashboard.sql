create or replace view public.vista_veicoli_dashboard
with (security_invoker = true)
as
with ultimi_lavori as (
  select distinct on (mr.vehicle_id, mi.type)
    mr.vehicle_id,
    mi.type,
    mi.service_km,
    mi.service_date
  from public.maintenance_items mi
  join public.maintenance_records mr on mr.id = mi.record_id
  order by mr.vehicle_id, mi.type, mi.service_km desc
)
select
  v.id,
  v.owner_id,
  v.plate,
  v.brand,
  v.model,
  v.year,
  v.fuel,
  v.power_cv,
  v.displacement_cc,
  v.km_current,
  v.scadenza_revision_date,
  v.tagliando_interval_km,
  v.tire_change_interval_km,
  v.tire_rotation_interval_km,
  v.created_at,
  v.updated_at,
  v.distribution_intervall_km,
  max(u.service_km) filter (where u.type = 'tagliando')
    as last_tagliando_km,
  max(u.service_date) filter (where u.type = 'tagliando')
    as last_tagliando_date,
  max(u.service_km) filter (where u.type = 'distribuzione')
    as last_distribuzione_km,
  max(u.service_date) filter (where u.type = 'distribuzione')
    as last_distribuzione_date,
  max(u.service_km) filter (where u.type = 'pneumatici_cambio')
    as last_tire_change_km,
  max(u.service_date) filter (where u.type = 'pneumatici_cambio')
    as last_tire_change_date,
  max(u.service_km) filter (where u.type = 'pneumatici_inversione')
    as last_tire_rotation_km,
  max(u.service_date) filter (where u.type = 'pneumatici_inversione')
    as last_tire_rotation_date,
  max(u.service_date) filter (where u.type = 'revisione')
    as last_revision_date,
  coalesce(
    (
      select max(vh.created_at)
      from public.vehicle_history vh
      where vh.vehicle_id = v.id
    ),
    v.created_at
  ) as km_updated_at
from public.vehicles v
left join ultimi_lavori u on u.vehicle_id = v.id
group by v.id;
