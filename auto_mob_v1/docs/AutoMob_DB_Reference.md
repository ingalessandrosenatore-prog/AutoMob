# AutoMob — Database Reference

> ⚠️ **SUPERATO — non usare.** Nomi di RPC e schema qui descritti non corrispondono
> più al DB live (es. `add_maintenance_session`/`add_item_to_session` non esistono:
> la RPC reale è `crea_sessione_manutenzione`). Fonte di verità aggiornata:
> **`docs/DATABASE.md`**. Questo file resta solo per contesto storico.

> Documento operativo del database AutoMob su Supabase. Pensato per essere letto da uno sviluppatore umano **o da un agente AI** prima di scrivere codice client che tocchi il DB. Se segui questo documento, non puoi sbagliare gli INSERT, gli UPDATE e le chiamate RPC.

**Project ID Supabase:** `tvxcyjqaiyxmmhktwhdb`
**Region:** `eu-west-3`
**Postgres version:** `17.6`
**Schema applicativo:** `public`
**Versione schema:** v3 (manual mechanic activation)

---

## 1. Architettura in 30 secondi

AutoMob ha due tipi di utenti:
- **Proprietari** di veicoli — registrano la propria auto e tengono traccia della manutenzione
- **Meccanici** — pagano un abbonamento (gestione manuale dell'admin in v3), vengono associati a uno o più veicoli, possono registrare lavori per i loro clienti

Il database è composto da **8 tabelle** in `public`, più la tabella `auth.users` gestita internamente da Supabase. La logica di sicurezza è **interamente in Postgres** via Row Level Security (RLS): il client Flutter non può MAI bypassare le regole.

Ci sono **3 punti di scrittura "magici"** che il client deve conoscere:
1. **Signup**: `auth.signUp(data: {...})` e il trigger `handle_new_user` crea automaticamente `profiles` ed eventualmente `mechanics`. **Non fare INSERT manuali su queste tabelle dopo il signup.**
2. **Aggiungere una sessione di lavoro completa**: via RPC `add_maintenance_session(...)`, MAI con INSERT diretti.
3. **Aggiungere un item a una sessione esistente**: via RPC `add_item_to_session(...)`.

Tutto il resto (creare veicoli, aggiornare profilo, leggere dati) si fa con normali `.from('table').select/insert/update/delete()` di Supabase.

---

## 2. Concetto chiave: record vs item

Prima di andare avanti, è importante capire la distinzione concettuale:

- **`maintenance_records`** = una **sessione di lavoro**. Tipicamente una visita in officina o un blocco di lavori inseriti insieme dal proprietario. Ha **una sola data** e **un solo meccanico** (o nessuno se inserito dal proprietario).
- **`maintenance_items`** = le **singole voci** dentro la sessione. Una sessione del 29/04/2026 può contenere più item: tagliando + cambio gomme + sostituzione filtro aria, tutti registrati nello stesso intervento.

```
maintenance_records (1 sessione)
└── maintenance_items (N voci)
    └── maintenance_item_parts (M pezzi per voce)
```

**Un item non può esistere senza un record** (FK obbligatoria). Quindi le operazioni sono:

| Cosa vuoi fare | Come si fa |
|---|---|
| Registrare un nuovo intervento (record + items + parts) | `rpc('add_maintenance_session', ...)` |
| Aggiungere un item a un intervento esistente | `rpc('add_item_to_session', ...)` |
| Modificare un record o un item esistente | ❌ Vietato — lo storico è immutabile |
| Cancellare un record o un item | ❌ Vietato — se serve correggere, si crea un nuovo intervento correttivo |

**Perché lo storico è immutabile**: la manutenzione di un veicolo è un registro contabile. Modificare retroattivamente "il tagliando del 2024 era a 50.000 km, no scusa erano 51.000" rende lo storico inaffidabile per assicurazione, futuro acquirente, controversie. Si correggono gli errori facendo un nuovo intervento, non riscrivendo il passato.

---

## 3. Schema completo

### 3.1 `profiles`

Profilo applicativo di ogni utente, 1:1 con `auth.users`. Creata automaticamente dal trigger `handle_new_user`.

| Colonna | Tipo | Default | Note |
|---|---|---|---|
| `id` | `uuid` | — | PK, FK → `auth.users(id)` ON DELETE CASCADE |
| `role` | `text` | NULL | CHECK IN (`'proprietario'`, `'meccanico'`) |
| `full_name` | `text` | NULL | |
| `phone` | `text` | NULL | |
| `created_at` | `timestamptz` | `now()` | |
| `updated_at` | `timestamptz` | `now()` | Auto-aggiornato dal trigger `set_updated_at` |

**Operazioni client-side ammesse:**
- `SELECT` → solo il proprio profilo (`id = auth.uid()`)
- `UPDATE` → solo il proprio profilo
- `INSERT` → ❌ **MAI** (lo fa il trigger)
- `DELETE` → ❌ Si gestisce solo cancellando l'utente da `auth.users` (CASCADE pulisce tutto)

### 3.2 `mechanics`

Dati del meccanico. Esiste solo se `profiles.role = 'meccanico'`.

| Colonna | Tipo | Default | Note |
|---|---|---|---|
| `id` | `uuid` | `gen_random_uuid()` | PK |
| `user_id` | `uuid` | — | NOT NULL, UNIQUE, FK → `auth.users(id)` ON DELETE CASCADE |
| `mechanic_code` | `text` | — | NOT NULL, UNIQUE — **codice pubblico**, lo digita il proprietario |
| `business_name` | `text` | — | NOT NULL |
| `vat_number` | `text` | NULL | Partita IVA |
| `address` | `text` | NULL | |
| `is_active` | `boolean` | `false` | Settato manualmente da admin quando il meccanico paga |
| `created_at` | `timestamptz` | `now()` | |
| `updated_at` | `timestamptz` | `now()` | |

**Gestione attivazione (v3 — manuale):**

Tu, come admin, attivi il meccanico da Supabase Studio / SQL Editor quando ricevi il pagamento:

```sql
UPDATE public.mechanics SET is_active = true WHERE mechanic_code = 'MC-XXXX-Y';
```

Per disattivarlo (mancato rinnovo, problema):

```sql
UPDATE public.mechanics SET is_active = false WHERE mechanic_code = 'MC-XXXX-Y';
```

I veicoli a lui assegnati restano (le righe in `vehicle_mechanics` non si cancellano), lo storico resta visibile, ma:
- L'app del meccanico non riesce più a registrare nuovi lavori (la RPC alza eccezione)
- Nessun proprietario può assegnarlo come nuovo meccanico

In futuro, quando arriverà Stripe, queste 2 query manuali saranno sostituite da un webhook automatico, ma il flusso applicativo resta lo stesso.

**Operazioni client-side ammesse:**
- `SELECT` → il meccanico vede se stesso, **e** chiunque autenticato può vedere meccanici con `is_active = true` (per il lookup nel wizard)
- `UPDATE` → il meccanico modifica i propri dati anagrafici. **NON è in grado di settare `is_active = true`** perché in produzione il client non avrà mai questo bottone. È solo l'admin via Studio che lo fa.
- `INSERT` → ❌ **MAI** dal client (lo fa il trigger `handle_new_user`)
- `DELETE` → ❌ Mai. Si setta `is_active = false`.

### 3.3 `vehicles`

Anagrafica veicolo. **Non contiene campi denormalizzati** come `last_tagliando_km`: questi si ricavano sempre via query su `maintenance_items`.

| Colonna | Tipo | Default | Note |
|---|---|---|---|
| `id` | `uuid` | `gen_random_uuid()` | PK |
| `owner_id` | `uuid` | — | NOT NULL, FK → `auth.users(id)` ON DELETE CASCADE |
| `plate` | `text` | — | NOT NULL |
| `brand` | `text` | — | NOT NULL |
| `model` | `text` | — | NOT NULL |
| `year` | `int` | — | NOT NULL, CHECK 1900-2100 |
| `fuel` | `text` | — | NOT NULL, CHECK IN (`'benzina'`,`'diesel'`,`'gpl'`,`'metano'`,`'elettrico'`,`'ibrido'`) |
| `power_cv` | `int` | NULL | CHECK > 0 |
| `displacement_cc` | `int` | NULL | CHECK > 0 |
| `km_current` | `int` | `0` | NOT NULL, CHECK ≥ 0 |
| `next_revision_date` | `date` | NULL | Aggiornato dalla RPC quando si registra un item `'revisione'` |
| `tagliando_interval_km` | `int` | `15000` | NOT NULL, CHECK > 0 |
| `tire_change_interval_km` | `int` | `40000` | NOT NULL, CHECK > 0 |
| `tire_rotation_interval_km` | `int` | `10000` | NOT NULL, CHECK > 0 |
| `created_at` | `timestamptz` | `now()` | |
| `updated_at` | `timestamptz` | `now()` | Auto |

UNIQUE su `(owner_id, plate)` — uno stesso utente non può registrare la stessa targa due volte.

**Operazioni client-side ammesse:**
- `SELECT` → proprietario sui propri, oppure meccanico attivo assegnato
- `INSERT` → solo proprietario (`owner_id = auth.uid()`)
- `UPDATE` → solo proprietario. **OK aggiornare `km_current` da soli** quando l'utente fa un check senza lavoro (modale "Aggiorna KM"). Quando invece c'è un lavoro registrato, è la RPC a farlo
- `DELETE` → solo proprietario

### 3.4 `vehicle_mechanics`

Tabella ponte N:M veicolo ↔ meccanico.

| Colonna | Tipo | Default | Note |
|---|---|---|---|
| `id` | `uuid` | `gen_random_uuid()` | PK |
| `vehicle_id` | `uuid` | — | NOT NULL, FK → `vehicles(id)` ON DELETE CASCADE |
| `mechanic_id` | `uuid` | — | NOT NULL, FK → `mechanics(id)` ON DELETE RESTRICT |
| `assigned_at` | `timestamptz` | `now()` | |

UNIQUE su `(vehicle_id, mechanic_id)`.

**Operazioni client-side ammesse:**
- `SELECT` → proprietario del veicolo, **o** il meccanico stesso
- `INSERT` → solo proprietario, e SOLO verso un meccanico con `is_active = true` (la policy lo controlla)
- `DELETE` → solo proprietario
- `UPDATE` → ❌ Non ha senso, si cancella e si reinserisce

### 3.5 `maintenance_records`

Sessione di lavoro: una visita in officina o un inserimento manuale.

| Colonna | Tipo | Default | Note |
|---|---|---|---|
| `id` | `uuid` | `gen_random_uuid()` | PK |
| `vehicle_id` | `uuid` | — | NOT NULL, FK → `vehicles(id)` ON DELETE CASCADE |
| `mechanic_id` | `uuid` | NULL | FK → `mechanics(id)` ON DELETE SET NULL — nullable se inserito dal proprietario |
| `service_date` | `date` | — | NOT NULL |
| `notes` | `text` | NULL | |
| `created_at` | `timestamptz` | `now()` | |

**Operazioni client-side ammesse:**
- `SELECT` → proprietario o meccanico assegnato (anche disattivato, in sola lettura — lo storico resta visibile)
- `INSERT/UPDATE/DELETE` → ❌ **VIETATI dal client.** Per creare un nuovo record con i suoi items, usa `rpc('add_maintenance_session', ...)`. Non puoi creare un record vuoto e riempirlo dopo.

### 3.6 `maintenance_items`

Voci dentro una sessione (tagliando, distribuzione, ecc.).

| Colonna | Tipo | Default | Note |
|---|---|---|---|
| `id` | `uuid` | `gen_random_uuid()` | PK |
| `record_id` | `uuid` | — | NOT NULL, FK → `maintenance_records(id)` ON DELETE CASCADE |
| `type` | `text` | — | NOT NULL, CHECK IN (`'tagliando'`,`'distribuzione'`,`'revisione'`,`'pneumatici_cambio'`,`'pneumatici_inversione'`,`'altro'`) |
| `custom_name` | `text` | NULL | NOT NULL **solo se** `type = 'altro'` |
| `service_km` | `int` | — | NOT NULL, CHECK ≥ 0 |
| `service_date` | `date` | — | NOT NULL |
| `next_service_km` | `int` | NULL | Se valorizzato, CHECK > `service_km` |
| `next_service_date` | `date` | NULL | |
| `notes` | `text` | NULL | |
| `created_at` | `timestamptz` | `now()` | |

⚠️ **CHECK constraint accoppiato:** `(type='altro' AND custom_name IS NOT NULL)` OR `(type<>'altro' AND custom_name IS NULL)`. Non barare.

**Operazioni client-side ammesse:**
- `SELECT` → chi vede il `record_id` (cascade dei permessi sul record)
- `INSERT` → ❌ Solo via RPC. Le due opzioni:
  - `rpc('add_maintenance_session', ...)` quando crei un intervento da zero (record + items insieme)
  - `rpc('add_item_to_session', ...)` quando aggiungi un item a un record già esistente
- `UPDATE/DELETE` → ❌ Lo storico è immutabile

### 3.7 `parts`

Catalogo ricambi condiviso.

| Colonna | Tipo | Default | Note |
|---|---|---|---|
| `id` | `uuid` | `gen_random_uuid()` | PK |
| `name` | `text` | — | NOT NULL |
| `code` | `text` | NULL | UNIQUE se valorizzato |
| `category` | `text` | NULL | |
| `unit` | `text` | `'pz'` | NOT NULL, CHECK IN (`'pz'`,`'l'`,`'kg'`,`'m'`) |
| `created_at` | `timestamptz` | `now()` | |

**Operazioni client-side ammesse:**
- `SELECT` → tutti gli autenticati
- `INSERT/UPDATE/DELETE` → ❌ Solo via SQL Editor admin (service_role key). **Non aggiungere parts dal client app.**

### 3.8 `maintenance_item_parts`

Pezzi usati in un singolo item.

| Colonna | Tipo | Default | Note |
|---|---|---|---|
| `id` | `uuid` | `gen_random_uuid()` | PK |
| `item_id` | `uuid` | — | NOT NULL, FK → `maintenance_items(id)` ON DELETE CASCADE |
| `part_id` | `uuid` | — | NOT NULL, FK → `parts(id)` ON DELETE RESTRICT |
| `quantity` | `numeric(10,2)` | `1` | NOT NULL, CHECK > 0 |
| `unit_price` | `numeric(10,2)` | NULL | CHECK ≥ 0 |
| `notes` | `text` | NULL | |

UNIQUE su `(item_id, part_id)`.

**Operazioni client-side ammesse:**
- `SELECT` → chi vede l'`item_id`
- `INSERT/UPDATE/DELETE` → ❌ Solo via le due RPC (annidato dentro `add_maintenance_session` o `add_item_to_session`)

---

## 4. Trigger e funzioni

### 4.1 `handle_new_user()` — trigger AFTER INSERT su `auth.users`

Si attiva automaticamente al `auth.signUp()`. Legge `raw_user_meta_data` e popola `profiles` (sempre) e `mechanics` (se ruolo meccanico).

**Campi accettati in `data`:**

Per **proprietario**:
```typescript
{
  role: 'proprietario',     // OBBLIGATORIO
  full_name?: string,
  phone?: string,
}
```

Per **meccanico**:
```typescript
{
  role: 'meccanico',        // OBBLIGATORIO
  full_name?: string,
  phone?: string,
  mechanic_code: string,    // OBBLIGATORIO, deve essere UNIQUE globalmente
  business_name: string,    // OBBLIGATORIO
  vat_number?: string,
  address?: string,
}
```

**Errori possibili al signup:**
- `Il ruolo deve essere proprietario o meccanico` → `role` mancante o invalido
- `mechanic_code obbligatorio per i meccanici`
- `business_name obbligatorio per i meccanici`
- `duplicate key value violates unique constraint "mechanics_mechanic_code_key"` → codice già usato. Mappare lato app a "Codice meccanico già in uso".

**Effetto al signup di un meccanico:** la riga viene creata con `is_active = false`. L'app del meccanico mostrerà una schermata "in attesa di attivazione" finché tu non setti `is_active = true` dal Supabase Studio.

### 4.2 `set_updated_at()` — trigger BEFORE UPDATE su 3 tabelle

Setta `NEW.updated_at = now()` automaticamente. Attaccato a `profiles`, `mechanics`, `vehicles`.

### 4.3 `add_maintenance_session(...)` — RPC transazionale (caso principale)

Crea una sessione completa: 1 `maintenance_records` + N `maintenance_items` + M `maintenance_item_parts` in una transazione atomica. Aggiorna anche `vehicles.km_current`.

**Firma:**
```sql
add_maintenance_session(
  p_vehicle_id   uuid,
  p_mechanic_id  uuid,           -- NULL se l'inserisce il proprietario
  p_service_date date,
  p_new_km       integer,
  p_notes        text,
  p_items        jsonb           -- array di items, vedi sotto
) RETURNS uuid                    -- l'id del record creato
```

**Formato `p_items` (sempre array, anche con un solo elemento):**
```json
[
  {
    "type": "tagliando",
    "custom_name": null,
    "service_km": 50000,
    "service_date": "2026-04-29",
    "next_service_km": 65000,
    "next_service_date": null,
    "notes": "Olio Mobil 1 5W30",
    "parts": [
      {
        "part_id": "uuid-del-pezzo-dal-catalogo",
        "quantity": 1,
        "unit_price": 25.50,
        "notes": null
      }
    ]
  }
]
```

**Note sui campi item:**
- `service_km` → se omesso, viene preso `p_new_km`
- `service_date` → se omesso, viene preso `p_service_date`
- `parts` → opzionale (un item può non avere pezzi)
- `custom_name` → SOLO se `type = 'altro'`, altrimenti NULL

**Comportamenti speciali:**
- Se uno degli items ha `type = 'revisione'` e `next_service_date` valorizzato, la RPC aggiorna anche `vehicles.next_revision_date`
- `p_new_km` non può essere inferiore a `vehicles.km_current` corrente (no regressioni)
- Almeno un item nell'array, altrimenti la RPC alza eccezione

**Validazioni di permesso:**
- Caller deve essere `owner_id` del veicolo, **oppure**
- Caller deve essere un meccanico con `is_active = true` e con riga in `vehicle_mechanics` per quel veicolo

Se entrambi falliscono → errore `'Non autorizzato a registrare lavori su questo veicolo'`.

### 4.4 `add_item_to_session(...)` — RPC per item aggiuntivo

Aggiunge un singolo item (con eventuali parts) a una sessione esistente. **Non aggiorna `km_current`** (per quello usa la RPC principale).

**Firma:**
```sql
add_item_to_session(
  p_record_id  uuid,
  p_item       jsonb            -- singolo item (NON array)
) RETURNS uuid                    -- l'id dell'item creato
```

**Formato `p_item` (oggetto, non array):**
```json
{
  "type": "pneumatici_inversione",
  "service_km": 50000,
  "service_date": "2026-04-29",
  "next_service_km": 60000,
  "parts": []
}
```

**Quando usarla:**
- Il meccanico ha registrato il tagliando, e si ricorda dopo 5 minuti che ha fatto anche l'inversione gomme
- Vuole aggiungere una voce "altro" al lavoro di stamattina senza creare una nuova sessione

**Quando NON usarla:**
- Per una nuova visita in un altro giorno → quella è una nuova sessione, usa `add_maintenance_session`

**Validazioni di permesso:** stesse della prima RPC (proprietario o meccanico attivo assegnato).

---

## 5. Flussi tipici (lato Flutter / client)

### 5.1 Signup proprietario

```dart
final response = await supabase.auth.signUp(
  email: 'mario@example.com',
  password: '...',
  data: {
    'role': 'proprietario',
    'full_name': 'Mario Rossi',
    'phone': '+39...',
  },
);
// ✅ A questo punto profiles esiste già, role='proprietario'
// ✅ Nessuna scrittura aggiuntiva da fare
```

### 5.2 Signup meccanico

```dart
final response = await supabase.auth.signUp(
  email: 'luca@officina.it',
  password: '...',
  data: {
    'role': 'meccanico',
    'full_name': 'Luca Bianchi',
    'phone': '+39...',
    'mechanic_code': 'MC-7742-X',
    'business_name': 'Officina Bianchi',
    'vat_number': '01234567890',
    'address': 'Via Roma 1, Milano',
  },
);
// ✅ profiles + mechanics creati in transazione dal trigger
// ✅ is_active = false di default
// ⚠️ App meccanico mostrerà schermata "in attesa di attivazione"
//    finché tu non setti is_active=true da Supabase Studio dopo il pagamento
```

### 5.3 Aggiungere veicolo (proprietario)

```dart
final vehicle = await supabase.from('vehicles').insert({
  'owner_id': supabase.auth.currentUser!.id,
  'plate': 'AB123CD',
  'brand': 'Alfa Romeo',
  'model': 'Stelvio',
  'year': 2021,
  'fuel': 'diesel',
  'power_cv': 210,
  'displacement_cc': 2143,
  'km_current': 42850,
  'next_revision_date': '2027-01-15',
  // intervalli usano default se non passati
}).select().single();
```

Per inserire **manutenzioni storiche** dal wizard (es. "ultimo tagliando 6 mesi fa") si usa `add_maintenance_session` con `p_mechanic_id = null` e `p_service_date` nel passato.

### 5.4 Lookup meccanico via codice (wizard)

```dart
final mech = await supabase
  .from('mechanics')
  .select('id, mechanic_code, business_name')
  .eq('mechanic_code', userInput)
  .eq('is_active', true)
  .maybeSingle();

if (mech == null) {
  // Codice non valido o meccanico non attivo
}
```

### 5.5 Assegnare meccanico al veicolo

```dart
await supabase.from('vehicle_mechanics').insert({
  'vehicle_id': vehicleId,
  'mechanic_id': mechanicId,
});
// Se il meccanico non è attivo, RLS rifiuta con errore.
```

### 5.6 Aggiornare km del veicolo (senza lavoro)

Quando l'utente apre la modale "Aggiorna KM":

```dart
await supabase.from('vehicles')
  .update({'km_current': newKm})
  .eq('id', vehicleId);
```

### 5.7 Registrare un nuovo intervento completo

```dart
final recordId = await supabase.rpc('add_maintenance_session', params: {
  'p_vehicle_id': vehicleId,
  'p_mechanic_id': mechanicId,    // o null se lo inserisce il proprietario
  'p_service_date': '2026-04-29',
  'p_new_km': 50000,
  'p_notes': 'Tagliando regolare',
  'p_items': [
    {
      'type': 'tagliando',
      'service_km': 50000,
      'service_date': '2026-04-29',
      'next_service_km': 65000,
      'parts': [
        {'part_id': filtroOlioId, 'quantity': 1, 'unit_price': 12.50},
        {'part_id': olioMotoreId, 'quantity': 4, 'unit_price': 18.00},
      ],
    },
    {
      'type': 'pneumatici_inversione',
      'service_km': 50000,
      'service_date': '2026-04-29',
      'next_service_km': 60000,
    },
  ],
});
// Tutto atomico: km veicolo + record + 2 items + 2 parts
```

### 5.8 Aggiungere un item a un intervento esistente

```dart
final newItemId = await supabase.rpc('add_item_to_session', params: {
  'p_record_id': existingRecordId,
  'p_item': {
    'type': 'altro',
    'custom_name': 'Sostituzione tergicristalli',
    'service_km': 50000,
    'service_date': '2026-04-29',
    'parts': [
      {'part_id': tergiAnterioriId, 'quantity': 2, 'unit_price': 15.00},
    ],
  },
});
```

### 5.9 Caricare la home del proprietario

```dart
// Tutti i veicoli del proprietario
final vehicles = await supabase
  .from('vehicles')
  .select()
  .order('created_at', ascending: false);

// Per ogni veicolo, l'ultimo tagliando
final lastTagliando = await supabase
  .from('maintenance_items')
  .select('service_km, service_date, next_service_km, maintenance_records!inner(vehicle_id)')
  .eq('type', 'tagliando')
  .eq('maintenance_records.vehicle_id', vehicleId)
  .order('service_date', ascending: false)
  .limit(1)
  .maybeSingle();
```

### 5.10 Caricare lo storico completo di un veicolo

```dart
final history = await supabase
  .from('maintenance_records')
  .select('''
    id, service_date, notes,
    mechanic:mechanics(business_name),
    items:maintenance_items(
      id, type, custom_name, service_km, service_date, next_service_km, next_service_date,
      parts:maintenance_item_parts(
        quantity, unit_price, notes,
        part:parts(name, code, category, unit)
      )
    )
  ''')
  .eq('vehicle_id', vehicleId)
  .order('service_date', ascending: false);
```

Una sola query, tre livelli di JOIN nested. Supabase lo risolve via PostgREST.

---

## 6. Operazioni admin (su Supabase Studio o via SQL Editor)

### Attivare un meccanico dopo il pagamento
```sql
UPDATE public.mechanics SET is_active = true WHERE mechanic_code = 'MC-7742-X';
```

### Disattivare un meccanico
```sql
UPDATE public.mechanics SET is_active = false WHERE mechanic_code = 'MC-7742-X';
```

### Aggiungere ricambi al catalogo
```sql
INSERT INTO public.parts (name, code, category, unit) VALUES
('Filtro olio Mann W712/75', 'MANN-W712-75', 'filtri', 'pz'),
('Olio motore Mobil 1 5W30', 'MOBIL1-5W30', 'lubrificanti', 'l'),
('Pastiglie freno Brembo P85020', 'BREMBO-P85020', 'pastiglie', 'pz');
```

### Vedere tutti i meccanici e il loro stato
```sql
SELECT mechanic_code, business_name, is_active, created_at 
FROM public.mechanics 
ORDER BY created_at DESC;
```

---

## 7. Cose che NON si fanno mai dal client

| Tentativo | Cosa succede |
|---|---|
| `INSERT INTO profiles ...` dal client | RLS blocca (no policy INSERT) |
| `INSERT INTO mechanics ...` dal client | RLS blocca (no policy INSERT) |
| `INSERT INTO maintenance_records ...` dal client | RLS blocca |
| `INSERT INTO maintenance_items ...` dal client | RLS blocca |
| `INSERT INTO maintenance_item_parts ...` dal client | RLS blocca |
| `INSERT INTO parts ...` dal client | RLS blocca |
| `UPDATE/DELETE` su records, items, item_parts | RLS blocca + scelta di design (immutabilità) |
| Insert in `vehicle_mechanics` con meccanico `is_active=false` | RLS blocca |
| `UPDATE vehicles SET owner_id = ...` su veicolo non proprio | RLS blocca |
| Diminuire `km_current` di un veicolo durante un lavoro | RPC alza eccezione |

---

## 8. Errori comuni e come gestirli lato app

| Codice errore Postgres | Significato | Messaggio utente suggerito |
|---|---|---|
| `23505` UNIQUE su `mechanics_mechanic_code_key` | Codice meccanico duplicato | "Questo codice meccanico è già in uso" |
| `23505` UNIQUE su `vehicles_owner_plate_unique` | Targa già registrata dallo stesso utente | "Hai già registrato un veicolo con questa targa" |
| `23514` CHECK su `custom_name_only_for_altro` | custom_name passato con type ≠ altro | Bug del client, da fixare |
| `23514` CHECK su `fuel_valid` | Carburante non valido | "Tipo di carburante non riconosciuto" |
| `42501` insufficient_privilege | RLS ha bloccato | "Non hai i permessi per questa operazione" |
| `P0001 raise_exception` con messaggio dalla RPC | Validazione fallita nella RPC | Mostrare il messaggio della RPC tradotto |

---

## 9. Quick reference — il decision tree per l'agente

Quando devi scrivere codice client che tocca il DB, segui questo albero:

```
DEVO LEGGERE QUALCOSA?
├─ profilo proprio → SELECT FROM profiles WHERE id = auth.uid()
├─ veicoli del proprietario → SELECT FROM vehicles
├─ veicoli di un meccanico → SELECT FROM vehicles (RLS filtra automaticamente)
├─ storico di un veicolo → SELECT FROM maintenance_records con join nested
├─ catalogo pezzi → SELECT FROM parts
└─ ricerca meccanico per codice → SELECT FROM mechanics WHERE mechanic_code=... AND is_active=true

DEVO REGISTRARE UN UTENTE?
└─ supabase.auth.signUp(data: {role, ...}) — il trigger fa tutto

DEVO REGISTRARE UN VEICOLO?
└─ INSERT INTO vehicles (sono io il proprietario)

DEVO ASSEGNARE/RIMUOVERE UN MECCANICO A UN VEICOLO?
├─ assegnare → INSERT INTO vehicle_mechanics
└─ rimuovere → DELETE FROM vehicle_mechanics

DEVO AGGIORNARE I KM SENZA UN LAVORO?
└─ UPDATE vehicles SET km_current=...

DEVO REGISTRARE UN NUOVO INTERVENTO (visita in officina)?
└─ supabase.rpc('add_maintenance_session', params: {...})
   Crea record + items + parts insieme.

DEVO AGGIUNGERE UN ITEM A UN INTERVENTO ESISTENTE?
└─ supabase.rpc('add_item_to_session', params: {...})

DEVO MODIFICARE/CANCELLARE UNO STORICO?
└─ ❌ Vietato. Lo storico è immutabile.
   Per correzioni: nuovo intervento correttivo via add_maintenance_session.

DEVO ATTIVARE/DISATTIVARE UN MECCANICO?
└─ Solo da Supabase Studio: UPDATE mechanics SET is_active=...
```

---

## 10. Indici e performance

| Indice | Tabella | Colonne | Serve per |
|---|---|---|---|
| `idx_vehicles_owner` | `vehicles` | `(owner_id)` | Home proprietario |
| `idx_vehicle_mechanics_mechanic` | `vehicle_mechanics` | `(mechanic_id)` | Lista veicoli del meccanico |
| `idx_vehicle_mechanics_vehicle` | `vehicle_mechanics` | `(vehicle_id)` | Lista meccanici del veicolo |
| `idx_records_vehicle_date` | `maintenance_records` | `(vehicle_id, service_date DESC)` | Storico ordinato |
| `idx_records_mechanic_date` | `maintenance_records` | `(mechanic_id, service_date DESC) WHERE mechanic_id IS NOT NULL` | Lavori recenti meccanico |
| `idx_items_record` | `maintenance_items` | `(record_id)` | Voci di una sessione |
| `idx_items_type_date` | `maintenance_items` | `(type, service_date DESC)` | "Ultimo X di un veicolo" |
| `idx_mechanics_active` | `mechanics` | `(mechanic_code) WHERE is_active = true` | Lookup wizard veloce |
| `idx_item_parts_item` | `maintenance_item_parts` | `(item_id)` | Pezzi di un item |
| `idx_item_parts_part` | `maintenance_item_parts` | `(part_id)` | Reverse lookup uso di un pezzo |

---

## 11. Migration history

1. `automob_v2_drop_all` — drop di tutta la v1
2. `automob_v2_schema` — 8 tabelle + indici
3. `automob_v2_triggers` — trigger handle_new_user, set_updated_at, sync_mechanic_is_active
4. `automob_v2_rls_policies` — 19 policy RLS
5. `automob_v2_rpc_add_maintenance_session` — RPC sessione completa
6. `automob_v3_simplify_mechanic_status` — rimosse colonne abbonamento, attivazione manuale, rimosso trigger sync
7. `automob_v3_update_rpc_simplified` — RPC senza check scadenza
8. `automob_v3_rpc_add_item_to_session` — RPC per aggiunta item

Per modifiche future: **mai droppare**, usa `ALTER TABLE` o `CREATE OR REPLACE FUNCTION` in nuove migration con nome incrementale (es. `automob_v4_add_stripe_subscription`).

---

## 12. Roadmap — quando arriverà Stripe

Quando integri i pagamenti automatici, il flusso diventerà:
1. Aggiungi colonne `subscription_status`, `subscription_expires_at` a `mechanics`
2. Webhook Stripe → edge function → `UPDATE mechanics SET is_active=true, subscription_expires_at=...` 
3. Cron job giornaliero → `UPDATE mechanics SET is_active=false WHERE subscription_expires_at < now()`

Niente cambia lato client. Le RLS continuano a controllare `is_active`, indipendentemente da chi/cosa lo setta. Questa è la bellezza di aver mantenuto la logica semplice in v3.

---

**Ultima revisione:** 2026-04-29
**Versione schema:** v3
