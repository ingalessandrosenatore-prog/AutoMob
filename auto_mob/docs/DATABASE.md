# AutoMob — Database (fonte di verità: Supabase live)

> Rigenerato dallo schema live il 2026-07-15. Se il codice o questo doc sembrano
> in disaccordo con Supabase, **fidati di Supabase** e rigenera questo file
> (query in fondo al documento). `docs/AutoMob_DB_Reference.md` è superato,
> non usarlo.

**Project ID:** `tvxcyjqaiyxmmhktwhdb` · **Region:** `eu-west-3` · **Postgres:** 17.6 · **Schema:** `public`

---

## Sicurezza registrazione veicolo

`public.mechanics`, `vehicle_lookup_results` e `vehicle_external_snapshots`
hanno RLS attiva. Il ruolo anon non ha grant su `mechanics`; un autenticato può
leggere le officine attive o la propria riga. L'audit completo delle vecchie
policy di manutenzione e dei grant GraphQL resta pianificato separatamente.

---

## Modifica registrazione veicolo live (15 luglio 2026)

La migration `20260715130000_vehicle_registration_lookup.sql` aggiunge
`vehicle_lookup_results`, `vehicle_external_snapshots`, le rispettive RLS e
l'estensione atomica di `crea_veicolo_con_storico`. Lo schema è ora presente
nel progetto live. Dettagli in `docs/VEHICLE_REGISTRATION.md`.

---

## 1. Concetto in 30 secondi

Il sistema di notifiche push (token dispositivo, outbox, consegne, regole e
Cron) e documentato in `docs/NOTIFICATIONS.md`. Firebase e stato verificato con
invii reali e i job sono attivi.

Due tipi di utenti: **proprietari** (registrano veicoli, tengono lo storico manutenzione)
e **meccanici** (attivati manualmente dall'admin, associabili a veicoli via `vehicle_mechanics`).
Tutta la sicurezza di riga è in Postgres (RLS): il client Flutter non la può bypassare.

**3 RPC "magiche"** — mai fare INSERT/UPDATE diretti per queste operazioni:
1. `crea_veicolo_con_storico(p_payload jsonb) → uuid` — crea un veicolo + storico iniziale, atomico.
2. `crea_sessione_manutenzione(p_payload jsonb) → uuid` — registra un intervento (1 record + 1 item + N parti).
3. `aggiorna_km_veicolo(p_vehicle_id uuid, p_nuovo_km integer) → integer` — aggiorna i km (salgono solo, mai indietro), ritorna i km effettivi salvati.

Tutto il resto (leggere veicoli, aggiornare profilo) è normale `.from('table').select/update()`.

**Trigger automatici** (mai da chiamare manualmente):
- `handle_new_user()` — al signup crea `profiles` (+ `mechanics` se il ruolo lo richiede).
- `registra_storico_km()` — scrive su `vehicle_history` quando cambiano i km.
- `set_updated_at()` — mantiene `updated_at` sincronizzato.

---

## 2. Tabelle

### `profiles` — RLS ✅
1:1 con `auth.users`, creata dal trigger `handle_new_user`.
`id (PK, FK→auth.users)`, `role` (`proprietario`|`meccanico`), `full_name`, `phone`, `created_at`, `updated_at`.
Policy: solo il proprio profilo (select/update `auth.uid() = id`).

### `vehicles` — RLS ✅
`id (PK)`, `owner_id (FK→auth.users)`, `plate`, `brand`, `model`, `year` (1900–2100), `fuel` (enum), `power_cv`, `displacement_cc`, `km_current` (aggiornato solo via RPC), `scadenza_revision_date`, `tagliando_interval_km` (default 15000), `tire_change_interval_km` (default 40000), `tire_rotation_interval_km` (default 10000), `distribution_intervall_km`, `created_at`, `updated_at`.
Policy: CRUD solo `owner_id = auth.uid()`.

### `mechanics` — RLS ✅
`id (PK)`, `user_id (FK→auth.users, unique)`, `mechanic_code` (unique, inserito dal proprietario nel wizard veicolo), `business_name`, `vat_number`, `address` (legacy compatibile), `street_address`, `postal_code` (CAP), `municipality_istat_code`, `number`, `email`, `is_active` (temporaneamente mantenuto perché lookup e collegamento veicolo lo usano), `created_at`, `updated_at`.

Il comune viene selezionato nell'app dal dataset ISTAT e persistito tramite il
codice ufficiale a sei cifre. Durante la transizione i nuovi campi indirizzo
sono nullable per non bloccare gli account esistenti; il wizard meccanico li
rende obbligatori per le nuove registrazioni.
Policy: select autenticato delle officine attive o della propria riga; update
solo della propria riga. Nessun grant anon.

### `vehicle_lookup_results` — RLS ✅
Risposta InfoTarga temporanea per il salvataggio atomico. Contiene owner, targa,
qualità, codice provider, campi normalizzati, payload grezzo, trace e scadenza a
7 giorni. L'utente legge solo le proprie righe; scrive la Edge Function.

### `vehicle_external_snapshots` — RLS ✅
Snapshot permanente 1:1 col veicolo. Conserva payload InfoTarga e campi estratti
di assicurazione, emissioni, neopatentati, revisione e furto. Leggibile soltanto
dal proprietario del veicolo.

### `vehicle_mechanics` — RLS ✅
Associazione N:N veicolo↔meccanico. `id (PK)`, `vehicle_id (FK)`, `mechanic_id (FK)`, `assigned_at`.
Policy insert: solo il proprietario del veicolo, e solo verso un meccanico `is_active = true`.

### `maintenance_records` — RLS ✅
Una **sessione di lavoro** (1 data, 1 meccanico opzionale). `id (PK)`, `vehicle_id (FK)`, `mechanic_id (FK, nullable)`, `service_date`, `created_at`.
**Immutabile**: niente policy UPDATE — solo insert (owner) e delete (owner). Per correggere un errore si crea un nuovo intervento, non si modifica lo storico.

### `maintenance_items` — RLS ✅
Le **singole voci** di una sessione. `id (PK)`, `record_id (FK→maintenance_records)`, `type` (enum: `tagliando|distribuzione|revisione|pneumatici_cambio|pneumatici_inversione|altro`), `custom_name` (nullable, richiesto se `type=altro`), `service_km`, `service_date`, `notes`, `created_at`.

### `parts` — RLS ✅
Catalogo pezzi (letto da tutti gli utenti autenticati). `id (PK, bigint identity)`, `name`.

### `maintenance_item_parts` — RLS ✅
Pezzi usati in un item. `id (PK)`, `item_id (FK→maintenance_items)`, `part_id (FK→parts)`, `quantity` (default 1, >0), `unit_price` (nullable), `notes`.

### `vehicle_history` — RLS ✅
Log km nel tempo, scritto solo dal trigger `registra_storico_km`. `id (PK)`, `vehicle_id (FK)`, `km`, `event_type` (enum: `creazione|manutenzione|aggiornamento_km`), `created_at`. Solo select per il proprietario, nessuna scrittura diretta dal client.

```
vehicles
├── vehicle_mechanics (N:N con mechanics)
├── vehicle_history (log km, sola lettura per il client)
└── maintenance_records (1 sessione)
    └── maintenance_items (N voci)
        └── maintenance_item_parts (M pezzi, FK verso parts)
```

---

## 3. Come rigenerare questo documento

Quando lo schema cambia, rilancia queste query (via Supabase MCP `execute_sql`,
project_id `tvxcyjqaiyxmmhktwhdb`) e aggiorna le sezioni sopra:

```sql
-- Tabelle + colonne: usa il tool list_tables(verbose: true)

-- Funzioni RPC / trigger
select p.proname, pg_get_function_identity_arguments(p.oid) as arguments,
       pg_get_function_result(p.oid) as return_type, p.prosecdef as security_definer
from pg_proc p join pg_namespace n on p.pronamespace = n.oid
where n.nspname = 'public' order by p.proname;

-- Policy RLS
select tablename, policyname, cmd, roles, qual, with_check
from pg_policies where schemaname = 'public' order by tablename, policyname;
```
