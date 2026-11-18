alter table public.parts add column catalog_active boolean not null default false;

-- Keep existing IDs for equivalent parts. Inactive IDs remain available to
-- historical work logs until the test dataset is cleaned separately.
insert into public.parts (id, name, category, catalog_active)
overriding system value
values
  (200, 'Olio motore', 'tagliando', true),
  (15, 'Filtro olio', 'tagliando', true),
  (16, 'Filtro aria', 'tagliando', true),
  (203, 'Filtro GPL/metano', 'tagliando', true),
  (17, 'Filtro antipolline', 'tagliando', true),
  (18, 'Filtro carburante', 'tagliando', true),
  (78, 'Liquido antigelo', 'tagliando', true),
  (230, 'AdBlue', 'tagliando', true),
  (231, 'Albero di trasmissione', 'telaio', true),
  (43, 'Semiassi', 'telaio', true),
  (232, 'Bracci anteriori e posteriori', 'telaio', true),
  (233, 'Ammortizzatori anteriori e posteriori', 'telaio', true),
  (234, 'Supporti degli ammortizzatori', 'telaio', true),
  (235, 'Cuscinetti degli ammortizzatori', 'telaio', true),
  (236, 'Tamponi di fine corsa degli ammortizzatori', 'telaio', true),
  (237, 'Giunti omocinetici', 'telaio', true),
  (238, 'Cuffie', 'telaio', true),
  (239, 'Biellette della barra stabilizzatrice (destra e sinistra)', 'telaio', true),
  (240, 'Barra di torsione', 'telaio', true),
  (35, 'Scatola dello sterzo', 'telaio', true),
  (241, 'Snodi assiali (destro e sinistro)', 'telaio', true),
  (242, 'Tiranti della scatola dello sterzo (destro e sinistro)', 'telaio', true),
  (243, 'Cuscinetti ruota (anteriori e posteriori, destri e sinistri)', 'telaio', true),
  (244, 'Mozzi ruota (anteriori e posteriori, destri e sinistri)', 'telaio', true),
  (206, 'Kit distribuzione e cuscinetti', 'motore', true),
  (74, 'Pompa dell''acqua', 'motore', true),
  (8, 'Candelette', 'motore', true),
  (7, 'Candele', 'motore', true),
  (54, 'Bobine di accensione', 'motore', true),
  (52, 'Motorino di avviamento', 'motore', true),
  (51, 'Alternatore', 'motore', true),
  (245, 'Compressore', 'motore', true),
  (246, 'Pompa dell''idroguida', 'motore', true),
  (247, 'Guarnizione del coperchio punterie', 'motore', true),
  (248, 'Rettifica della testata', 'motore', true),
  (75, 'Valvola termostatica', 'motore', true),
  (249, 'Collettore di aspirazione', 'motore', true),
  (250, 'Turbina', 'motore', true),
  (251, 'Revisione del motore', 'motore', true),
  (252, 'Sostituzione con motore usato', 'motore', true),
  (253, 'Albero a camme', 'motore', true),
  (82, 'Iniettori', 'motore', true),
  (81, 'Pompa del carburante', 'motore', true),
  (12, 'Pompa dell''olio', 'motore', true),
  (47, 'Collettore di scarico', 'motore', true),
  (45, 'Marmitta', 'motore', true),
  (254, 'Supporto lato distribuzione', 'motore', true),
  (255, 'Supporto lato cambio', 'motore', true),
  (256, 'Supporto a bielletta del cambio', 'motore', true),
  (257, 'Valvola EGR', 'motore', true),
  (258, 'Filtro antiparticolato (DPF)', 'motore', true),
  (259, 'Pulizia del filtro antiparticolato (DPF)', 'motore', true),
  (260, 'Radiatore motore', 'motore', true),
  (261, 'Radiatore del riscaldamento abitacolo', 'motore', true),
  (262, 'Intercooler', 'motore', true),
  (263, 'Radiatore del climatizzatore', 'motore', true),
  (77, 'Ventola del radiatore', 'motore', true),
  (264, 'Cuscinetti', 'cambio', true),
  (201, 'Olio cambio', 'cambio', true),
  (265, 'Kit frizione', 'cambio', true),
  (39, 'Volano', 'cambio', true),
  (266, 'Forcella di disinnesto della frizione', 'cambio', true),
  (22, 'Dischi anteriori', 'freni', true),
  (23, 'Dischi posteriori', 'freni', true),
  (267, 'Pinze anteriori', 'freni', true),
  (268, 'Pinze posteriori', 'freni', true),
  (20, 'Pastiglie anteriori', 'freni', true),
  (21, 'Pastiglie posteriori', 'freni', true),
  (269, 'Sensori di usura delle pastiglie', 'freni', true),
  (270, 'Tubi delle pinze freno anteriori', 'freni', true),
  (271, 'Tubi delle pinze freno posteriori', 'freni', true),
  (272, 'Pompa ABS', 'freni', true),
  (273, 'Centralina ABS', 'elettronica', true),
  (274, 'Centralina motore', 'elettronica', true),
  (275, 'Body computer', 'elettronica', true),
  (58, 'Fusibili', 'elettronica', true),
  (276, 'Sensore dell''angolo di sterzo', 'elettronica', true),
  (277, 'Sensore di velocità della ruota', 'elettronica', true),
  (278, 'Centralina della scatola dello sterzo', 'elettronica', true),
  (86, 'Pneumatici', 'gomme', true),
  (87, 'Cerchi', 'gomme', true),
  (279, 'Ricarica dell''aria condizionata', 'aria_condizionata', true),
  (26, 'Liquido freni', 'liquido_freni', true),
  (280, 'Spazzole tergicristallo', 'veicolo', true),
  (281, 'Lampadine', 'veicolo', true),
  (282, 'Sensori di parcheggio', 'veicolo', true),
  (202, 'Olio differenziale', 'cambio', true),
  (204, 'Serbatoio GPL', 'veicolo', true),
  (205, 'Bombole metano', 'veicolo', true)
on conflict (id) do update
set name = excluded.name,
    category = excluded.category,
    catalog_active = excluded.catalog_active;

do $$
begin
  execute format(
    'alter table public.parts alter column id restart with %s',
    (select greatest(max(id) + 1, 400) from public.parts)
  );
end;
$$;

create function public.get_work_log_parts(p_vehicle_id uuid)
returns table (
  part_id bigint, name text, category text, secondary_category text, work_type text
)
language sql
stable
security invoker
set search_path = ''
as $$
  select p.id, p.name, p.category::text,
    case p.id when 78 then 'liquido_antigelo' when 26 then 'freni' end,
    c.work_type
  from public.parts p
  left join public.vehicle_component_maintenance c
    on c.vehicle_id = p_vehicle_id and c.part_id = p.id
  where p.catalog_active
  order by p.name, p.id;
$$;
revoke all on function public.get_work_log_parts(uuid) from public, anon;
grant execute on function public.get_work_log_parts(uuid) to authenticated;

notify pgrst, 'reload schema';
