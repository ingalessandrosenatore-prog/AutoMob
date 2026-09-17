# AutoMob — Database (fonte di verità: Supabase live)

> Verificato sullo schema live il 2026-08-23. Se il codice o questo doc sembrano
> in disaccordo con Supabase, **fidati di Supabase** e rigenera questo file
> (query in fondo al documento). `docs/AutoMob_DB_Reference.md` è superato,
> non usarlo.

**Project ID:** `tvxcyjqaiyxmmhktwhdb` · **Region:** `eu-west-3` · **Postgres:** 17.6 · **Schema:** `public`

---

## Sicurezza registrazione veicolo

`public.mechanics`, `mechanic_subscriptions`, `vehicle_lookup_results` e
`vehicle_external_snapshots`
hanno RLS attiva. Il ruolo anon non ha grant su `mechanics`; un autenticato può
leggere solo la propria officina o quelle già collegate ai propri veicoli. La
ricerca di un codice passa dalla RPC autenticata e limitata. L'audit delle vecchie
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

**RPC applicative principali** — mai sostituirle con accessi diretti:
1. `crea_veicolo_con_storico(p_payload jsonb) → uuid` — crea un veicolo + storico iniziale, atomico.
2. `crea_sessione_manutenzione(p_payload jsonb) → uuid` — registra un intervento (1 record + 1 item + N parti).
3. `aggiorna_km_veicolo(p_vehicle_id uuid, p_nuovo_km integer) → integer` — aggiorna i km (salgono solo, mai indietro), ritorna i km effettivi salvati.
4. `verify_mechanic_code(p_code text) → jsonb` — verifica un codice officina
   attivo, con massimo 10 tentativi ogni 5 minuti per account.
5. `connect_vehicle_to_mechanic_by_code(p_vehicle_id uuid, p_code text) → jsonb`
   — verifica e collega atomicamente un'officina al veicolo del proprietario.
6. `get_mechanic_subscription_overview() → jsonb` — riepilogo piano, scadenza
   e conteggio veicoli del meccanico autenticato.

Tutto il resto (leggere veicoli, aggiornare profilo) è normale `.from('table').select/update()`.

**Trigger automatici** (mai da chiamare manualmente):
- `handle_new_user()` — al signup crea `profiles` e, per il meccanico, genera
  nel database il codice numerico univoco a sei cifre.
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
`id (PK)`, `user_id (FK→auth.users, unique)`, `mechanic_code` (testo numerico
a sei cifre, unique, generato da UUID officina + partita IVA con massimo 64
tentativi), `business_name`, `vat_number`, `address` (legacy compatibile),
`street_address`, `postal_code` (CAP), `municipality_istat_code`, `number`,
`email`, `is_active` (attivazione manuale), `created_at`, `updated_at`.

Il comune viene selezionato nell'app dal dataset ISTAT e persistito tramite il
codice ufficiale a sei cifre. Durante la transizione i nuovi campi indirizzo
sono nullable per non bloccare gli account esistenti; il wizard meccanico li
rende obbligatori per le nuove registrazioni.
Policy: select della propria riga o delle officine già collegate a un veicolo
posseduto; update solo della propria riga. Nessun grant anon. Un'officina non
collegata si cerca esclusivamente tramite `verify_mechanic_code`.

### `mechanic_subscriptions` — RLS ✅
Un record manuale per officina: `mechanic_id (PK/FK→mechanics)`, `plan_code`,
`status (active|paused|cancelled)`, `starts_at`, `expires_at`,
`vehicle_limit`, `updated_at`. Il client non ha accesso diretto alla tabella:
il meccanico legge soltanto il riepilogo derivato tramite RPC. Inserimento e
aggiornamento restano operazioni amministrative con `service_role`/SQL.

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
Le **singole voci** di una sessione. `id (PK)`, `record_id (FK→maintenance_records)`, `type` (`tagliando|distribuzione|revisione|pneumatici_cambio|pneumatici_inversione|motore|freni|telaio|elettronica|batteria|altro`), `custom_name` (opzionale per le categorie aggiuntive, richiesto se `type=altro`), `service_km`, `service_date`, `notes`, `created_at`.

### `future_work_records` — RLS ✅
Un gruppo di lavori futuri o problemi segnalati per un veicolo. `id (PK)`,
`vehicle_id (FK→vehicles)`, `created_by_user_id (FK→auth.users)`,
`mechanic_id (FK→mechanics, nullable)`, `reminder_date`, `done` e `created_at`.
`reminder_date` indica la data entro cui effettuare i lavori del gruppo. Il campo
`mechanic_id` viene valorizzato quando il record è creato dal meccanico; per
una segnalazione del proprietario resta `null`. Proprietario e meccanico
attualmente collegato possono leggere il record e modificarne soltanto `done`.

### `future_work_items` — RLS ✅
Le singole voci testuali di un record futuro. `id (PK)`,
`record_id (FK→future_work_records)`, `description` e `created_at`. Per ora non
contengono categorie, costi, date previste o ricambi.

La funzione `create_future_work_report(vehicle_id, description, reminder_date)`
esegue in un'unica transazione gli insert del record e della prima voce. È
eseguibile solo dal ruolo `authenticated`; RLS e proprietà del veicolo restano
attive perché la funzione usa `security invoker`.
La funzione `get_owner_dashboard_future_works()` restituisce, per ogni veicolo
accessibile, al massimo le tre voci più recenti appartenenti a record con
`done = false`; alimenta la timeline della Home senza dati mock.

### `parts` — RLS ✅
Catalogo pezzi (letto da tutti gli utenti autenticati). `id (PK, bigint identity)`, `name`, `category` (`part_category`: `motore|veicolo|gomme|telaio|elettronica|freni`).

### `maintenance_item_parts` — RLS ✅
Pezzi usati in un item. `id (PK)`, `item_id (FK→maintenance_items)`, `part_id (FK→parts)`, `quantity` (default 1, >0), `unit_price` (nullable), `notes`.

### `vehicle_history` — RLS ✅
Log km nel tempo, scritto solo dal trigger `registra_storico_km`. `id (PK)`, `vehicle_id (FK)`, `km`, `event_type` (enum: `creazione|manutenzione|aggiornamento_km`), `created_at`. Solo select per il proprietario, nessuna scrittura diretta dal client.

```
vehicles
├── vehicle_mechanics (N:N con mechanics)
├── vehicle_history (log km, sola lettura per il client)
├── future_work_records (N gruppi di lavori futuri)
│   └── future_work_items (N descrizioni)
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
