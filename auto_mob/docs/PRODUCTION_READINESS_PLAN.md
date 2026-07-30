# Piano di Produzione AutoMob — Analisi Chirurgica

> Data analisi: 2026-05-25
> Target produzione: fine settimana
> Stack: Flutter + Clean Architecture + BLoC + Go Router + Supabase + GetIt + fpdart

---

## 🔴 ALERT SECURITY CRITICO (BLOCKER PRODUZIONE)

**RLS DISABILITATO su 5 tabelle**: `mechanics`, `maintenance_records`, `maintenance_items`, `parts`, `maintenance_item_parts`.

Chiunque abbia l'anon key (pubblica, visibile dal client) può leggere/modificare TUTTI i record di TUTTI gli utenti. Questo è inaccettabile in produzione.

L'unica tabella protetta è `vehicles` (RLS attivo + filtro `owner_id`), ma tutte le tabelle di manutenzione collegate sono completamente aperte.

**SQL di base (NON eseguire senza prima scrivere le policy):**
```sql
ALTER TABLE public.mechanics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.parts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.maintenance_item_parts ENABLE ROW LEVEL SECURITY;
```
Senza policy questo BLOCCA tutto l'accesso. Scrivi prima le policy, poi attiva RLS.

---

## 📋 RECAP ARCHITETTURALE

### Feature presenti

| Feature       | Domain                          | Data                          | Presentation         | Stato                          |
|---------------|---------------------------------|-------------------------------|----------------------|--------------------------------|
| `auth`        | ✅                              | ✅                            | ✅                   | Funzionante                    |
| `vehicle`     | ✅                              | ✅                            | ✅ (wizard)          | Funzionante                    |
| `dashboard`   | ⚠️ (riusa `GetVehicles`)       | ❌ (nessun datasource proprio)| ✅                   | OK ma logica KPI in View       |
| `work_log`    | ⚠️ parziale                    | ❌ vuoto                      | ⚠️ UI ok, no save   | **NON funzionante**            |
| `servizi`     | ❌                              | ❌                            | ⚠️ stub             | Non implementato               |

### Schema DB (rilevante per WorkLog)

```
maintenance_records (sessione di intervento)
   ├── maintenance_items (intervento tipizzato: tagliando/distribuzione/ecc.)
   │       ├── maintenance_item_parts (quantità/prezzo/note per ogni pezzo)
   │       └── parts (catalogo 95 voci)
   └── (link a vehicles, mechanics)
```

L'entity `WorkLogItem` corrente **mescola** i concetti `maintenance_item` + `maintenance_item_parts` → questa ambiguità è il fix più importante da fare.

---

## 🏗️ PIANO IMPLEMENTAZIONE — FEATURE WORKLOG (AGGIUNTA)

### 1. Domain
- **Ridefinire entities** allineate al DB:
  - `MaintenanceSession` (= `maintenance_record`): `id`, `vehicleId`, `mechanicId?`, `serviceDate`, `items[]`
  - `MaintenanceItem`: `id`, `type` (EnumPopUp), `customName?`, `serviceKm`, `serviceDate`, `notes?`, `parts[]`
  - `MaintenancePart`: `id`, `partId`, `quantity`, `unitPrice?`, `notes?`
- **Repository** `WorklogRepo`:
  - `Future<Either<Failure, void>> createSession({required MaintenanceSession session})`
  - `Future<Either<Failure, List<Part>>> getPartsCatalog()` (sostituisce il Map hardcoded)
- **UseCase** `CreateMaintenanceSession` (chiama `repo.createSession`)
- **UseCase** `GetPartsCatalog` (cache 24h, parts cambiano raramente)

### 2. Data
- `WorklogRemoteDataSource` (interface + impl):
  - `Future<void> createSession(MaintenanceSessionModel)` → chiama RPC Supabase `crea_sessione_manutenzione` (atomica: insert record + items + parts in una transazione)
  - `Future<List<PartModel>> getParts()` → `from('parts').select()`
- `WorklogRepositoryImpl`: mappa exception → Failure (segui pattern di `VehicleRepositoryImpl`)
- Models: `MaintenanceSessionModel`, `MaintenanceItemModel`, `MaintenancePartModel`, `PartModel` con `toJson/fromJson`
- **RPC Supabase** lato DB: serve creare `crea_sessione_manutenzione(p_session jsonb)` analoga a `salva_veicolo_iniziale` con rollback automatico

### 3. Presentation
- **State**: aggiungere `WorkLogStatus { initial, loading, success, failure }` + `String? errorMessage` + `String vehicleId` (mancante) + `DateTime serviceDate`
- **Event**: `OnSubmitEvent` deve essere **senza payload** (i dati sono già nello state)
- **BLoC**:
  - `_onSubmitEvent`: emette loading → costruisce `MaintenanceSession` da `state` → chiama `CreateMaintenanceSession` → emit success/failure
  - Costruttore deve ricevere `WorklogRepo` + `CreateMaintenanceSession` via DI
- **DI**: registrare in `_initWorkLog` repo, datasource, usecase. Il BLoC factory deve riceverli.
- **AddWorkLogPopUp**: rimuovere `_selectedWorkType`, `_kmController`, `_dateController`, `_noteController` locali → BLoC è single source of truth (i `TextEditingController` ok, ma il valore di verità deve essere nello state)
- **vehicleId**: passarlo al BLoC nel costruttore (oggi è ignorato, `widget.id` mai usato nel save)
- Bottone SALVA: collegare a `context.read<WorkLogBloc>().add(OnSubmitEvent())` + `BlocListener` per chiudere il popup su success o mostrare snackbar su failure

---

## 🏗️ PIANO IMPLEMENTAZIONE — PAGINA STORICO WORKLOG

### Decisione architetturale chiave
**Riusare `DashboardBloc` per la lista veicoli** vs creare uno `WorkLogHistoryBloc` indipendente.

**Raccomandazione**: un nuovo `WorkLogHistoryBloc` che riceve `getVehicles` (usecase shared) + `getWorkLogsByVehicle`. Motivi:
- Disaccoppiamento: WorkLog non deve dipendere dallo stato della Dashboard
- Selezione veicolo è semanticamente diversa (qui filtra storico, lì pagina carosello)
- Permette di ricaricare i veicoli al pull-to-refresh senza toccare la Home

### 1. Domain (work_log)
- Repository (estendere `WorklogRepo`):
  - `Future<Either<Failure, List<MaintenanceSession>>> getSessionsByVehicle(String vehicleId)`
- UseCase `GetWorkLogsByVehicle`

### 2. Data
- `WorklogRemoteDataSource.getSessionsByVehicle(vehicleId)`:
  - Query nested: `maintenance_records` filtrato per `vehicle_id`, joined con `maintenance_items(*, maintenance_item_parts(*, parts(name)))` ordinato per `service_date desc`
  - Mapping in models

### 3. Presentation
- **State** `WorkLogHistoryState`: sealed (`Initial`, `Loading`, `Loaded(vehicles, selectedVehicleId, sessions)`, `Error`)
- **Events**: `LoadVehiclesAndHistory`, `SelectVehicle(id)`, `RefreshHistory`
- **WorkLogHistoryPage**: rimuovere `isSelct1/2`, `setState`, mock cards → `BlocBuilder<WorkLogHistoryBloc>` con shimmer/loader/empty/error states
- FAB "Aggiungi": passare `state.selectedVehicleId` (rimuove `'veicolo_id_mock'`)
- DI: registrare `WorkLogHistoryBloc` factory

---

## ⚠️ CRITICITÀ — PER PRIORITÀ

### 🔴 BLOCKER (devi sistemare prima della produzione)

1. **RLS disabilitato** — abilita RLS su tutte le 5 tabelle e scrivi policy:
   - `maintenance_records`: SELECT/INSERT/UPDATE solo se `vehicle_id IN (SELECT id FROM vehicles WHERE owner_id = auth.uid())` o se l'utente è meccanico assegnato
   - `maintenance_items`: stessa logica via `record_id → vehicle_id`
   - `maintenance_item_parts`: stessa logica via `item_id → record_id → vehicle_id`
   - `parts`: SELECT pubblico (è un catalogo), no INSERT/UPDATE/DELETE
   - `mechanics`: SELECT pubblico limitato, scrittura solo admin/owner del row
2. **Salvataggio WorkLog non funzionante** (`_onSubmitEvent` vuoto, `InsertWork.call` passa `[]` literal invece di `parts`, no repo impl, no datasource)
3. **vehicle_id hardcoded `'veicolo_id_mock'`** in `WorkLogHistoryPage:235`
4. **Recupero WorkLog hardcoded** (mock cards) in `WorkLogHistoryPage:171-218`
5. **KmUpdatePopUp non salva nulla** — `TextEditingController()` inline senza dispatch, "Salva aggiornamento" è solo testo decorativo
6. **Print con dati sensibili** in `vehicle_remote_data_source.dart:79-83, 113, 123, 127, 131, 137` — rimuovere o sostituire con logger condizionato
7. **Anon key hardcoded** in `injection_container.dart:50` — sposta in `.env` con `flutter_dotenv` (anche se publishable, è best practice)

### 🟠 ALTA (Clean Architecture non rispettata)

8. **Entity ambigua** `WorkLogItem` — mescola `maintenance_item` + `maintenance_item_parts`. Da splittare in 2 entity.
9. **Domain con entity orfane** — `MaintenanceRecord/Item/Part` definite in `MaintenanceEntity.dart` ma non usate
10. **Catalogo parts hardcoded** in 2 widget (`AddWorkLogPopUp:209-305` e `MidifyItem:11-107`) — duplicazione 95 voci × 2 file. Deve venire da `parts` table via usecase.
11. **Logica calcoli KPI in View** (`HomeView:213-244`) — `nextServTag`, `percTag`, etc. sono business logic, devono stare nel BLoC e arrivare già calcolati come `KpiSnapshot`
12. **`distribuzioneIntervalKm` hardcoded a 60000** in `HomeView:220` — manca `distributionIntervalKm` nell'entity `Vehicle` (esiste su DB come `distribution_intervall_km`!)
13. **Stato locale duplicato col BLoC** in `AddWorkLogPopUp._FirstPageAddWorkState` (`_selectedWorkType`, controllers) — antipattern
14. **OnSubmitEvent ha payload duplicato col state** (`type`, `currentKm`, `intervallKM`, `note`, `prossimoRichiamo`) — l'event dovrebbe essere vuoto, lo state è autosufficiente
15. **WorkLogState** non ha `status` (loading/success/error), `vehicleId`, `serviceDate` — il salvataggio non saprà mai cosa salvare
16. **DashboardBloc** dipende direttamente da `GetVehicles` della feature vehicle — accettabile ma andrebbe wrappato in un `GetDashboardData` usecase

### 🟡 MEDIA (junior smell, da sistemare in seguito)

17. **Naming convention disastrosa**: `MidifyItem` (Modify), `Cohice` (Choice), `prosssimoRichiamo`, `intervallKM`, `Bloc/dashboardBloc.dart` (lowercase), file italiani/inglesi mischiati, cartella `Entiti/` (Entities)
18. **`Map<String, dynamic>` cast unsafe** in `app_router.dart:68, 85` — può crashare se `extra` è null. Usa pattern matching o helper.
19. **`context.pop('/home')`** in `AddWorkLogPopUp:128`, `KmUpdatePopUp:63` — `pop` non accetta route, è semplicemente ignorato. Usa `context.pop()` o `context.go('/home')`
20. **`WorkLogState` constructor non `const`**, manca `const` su tutti i widget statici (perdita perf)
21. **`Colors.transparent.withOpacity(0)`** in `HomeView:43, WorkLogHistoryPage:52` — no-op, codice spazzatura
22. **`AmSparePartCard` quantity non validata** — possono essere 0 o negative
23. **`MultiBlocProvider` in `main.dart`** ha commenti `// BlocProvider<DashboardBloc>(...)` e `// BlocProvider<WorkLogBloc>(...)` — il fatto che usi `GetIt.I/sl()` inline rende inconsistente lo schema di provisioning
24. **`WorkLogBloc` registrato factory** ma `sl<WorkLogBloc>()` viene chiamato dentro `BlocProvider.create` ogni volta che il popup si apre — ok ma documenta che è scope-locale
25. **No tests** — nessun unit test su use case/repository
26. **`FunctionalPopUp` switch totalmente inutile** — tutti i 4 case ritornano lo stesso widget con gli stessi parametri
27. **`_kmController.text` letto due volte** (`onChanged` non usa `value`) in `AddWorkLogPopUp:370-374`
28. **Validation form mancante** — il salvataggio dovrebbe rifiutarsi se `currentKm == 0` o `vehicleId` vuoto

### 🟢 BASSA (cosmetica/refactor post-launch)

29. Hardcoded colors sparsi (`Color(0xFFE85A1A)`, etc.) — estrai in `AppTheme`
30. `print` per debug → introdurre logger condizionato (es. `Logger` package)
31. `ServiziPage` stub vuoto da implementare o nascondere il tab

---

## ✅ ORDINE OPERATIVO (chirurgico, fine settimana)

### Giorno 1 — Security DB
- [ ] Scrivi policy RLS per 5 tabelle e testale con SQL editor (impersonando 2 utenti diversi)
- [ ] Abilita RLS in produzione
- [ ] Crea RPC `crea_sessione_manutenzione(jsonb)` con transazione + rollback
- [ ] Rimuovi print con info sensibili da `vehicle_remote_data_source`
- [ ] Sposta anon key in `.env` (flutter_dotenv)

### Giorno 2 — WorkLog domain + data
- [ ] Riscrivi entity (`MaintenanceSession`, `MaintenanceItem`, `MaintenancePart`) eliminando ambiguità di `WorkLogItem`
- [ ] Aggiorna `WorklogRepo` con 3 firme: `createSession`, `getSessionsByVehicle`, `getPartsCatalog`
- [ ] Crea `WorklogRemoteDataSource` + impl (RPC + select)
- [ ] Crea `WorklogRepositoryImpl`
- [ ] Crea use cases `CreateMaintenanceSession`, `GetWorkLogsByVehicle`, `GetPartsCatalog`
- [ ] Aggiungi `distributionIntervalKm` all'entity `Vehicle` + `VehicleModel`
- [ ] DI in `_initWorkLog`

### Giorno 3 — WorkLog presentation (Add)
- [ ] Aggiungi `WorkLogStatus`, `vehicleId`, `serviceDate` a `WorkLogState`
- [ ] Pulisci `OnSubmitEvent` (no payload)
- [ ] Implementa `_onSubmitEvent` chiamando l'usecase
- [ ] Rimuovi stato locale da `AddWorkLogPopUp`, sostituiscilo con BLoC
- [ ] Bottone SALVA → dispatcha `OnSubmitEvent`, `BlocListener` chiude popup + snackbar
- [ ] Passa `vehicleId` reale (`widget.id`) al BLoC al create
- [ ] Sostituisci `Map<int,String> kParts` con caricamento da `GetPartsCatalog`

### Giorno 4 — WorkLog History Page
- [ ] Crea `WorkLogHistoryBloc` (event/state/bloc)
- [ ] Implementa `WorkLogHistoryPage` con `BlocBuilder` (loading/loaded/error/empty)
- [ ] Selezione veicolo via dispatch event
- [ ] FAB passa `selectedVehicleId` reale
- [ ] DI

### Giorno 5 — Aggiornamento KM + smoke test E2E
- [ ] Implementa `UpdateVehicleKm` usecase + repo + datasource (UPDATE su `vehicles.km_current`)
- [ ] Cabla `KmUpdatePopUp` al BLoC
- [ ] Sposta calcoli KPI in `DashboardBloc` (`KpiSnapshot`)
- [ ] Sistema `distribuzioneIntervalKm` hardcoded
- [ ] Test E2E: registrazione → aggiunta veicolo → aggiungi tagliando → vedi storico → aggiorna km → verifica KPI ricalcolato
- [ ] Rimuovi print residui

---

## 📎 RIFERIMENTI FILE

### File da modificare (priorità alta)
- `lib/features/work_log/domain/entiti/WorkLogItemEntity.dart` — splittare entity
- `lib/features/work_log/domain/entiti/MaintenanceEntity.dart` — completare o eliminare
- `lib/features/work_log/domain/repositories/WorklogRepo.dart` — riscrivere firme
- `lib/features/work_log/domain/usecase/InsertWork.dart` — eliminare/sostituire
- `lib/features/work_log/data/` — implementare `datasources/`, `repositories/`
- `lib/features/work_log/presentation/Bloc/work_log_*.dart` — aggiungere status + vehicleId
- `lib/features/work_log/presentation/widget/AddWorkLogPopUp.dart` — rimuovere stato locale
- `lib/features/work_log/presentation/page/WorkLogHistoryPage.dart` — rimuovere mock
- `lib/features/work_log/presentation/page/MidifyItem.dart` — rimuovere Map duplicato
- `lib/features/vehicle/domain/entities/vehicle.dart` — aggiungere `distributionIntervalKm`
- `lib/features/vehicle/data/models/VehicleModel.dart` — mappare `distribution_intervall_km`
- `lib/features/vehicle/presentation/widget/KmUpdatePopUp.dart` — collegare al BLoC
- `lib/features/dashboard/presentation/page/HomeView.dart` — spostare logica KPI
- `lib/features/dashboard/presentation/Bloc/dashboardBloc.dart` — aggiungere KpiSnapshot
- `lib/core/di/injection_container.dart` — registrare nuovi servizi WorkLog
- `lib/core/router/app_router.dart` — cast safe per `extra`
- `lib/features/vehicle/data/datasources/vehicle_remote_data_source.dart` — rimuovere print

### File DB / Supabase (priorità critica)
- Migration RLS policy (da creare)
- RPC `crea_sessione_manutenzione(jsonb)` (da creare)
- RPC `aggiorna_km_veicolo(uuid, int)` (opzionale, può essere UPDATE diretto)

---

## 🚨 NOTE FINALI

- **Non aggiungere feature nuove** in questa settimana: solo fix dei blocker e completamento WorkLog.
- **Test E2E manuale** prima di ogni merge — non c'è suite automatica.
- **Backup DB produzione** prima di applicare migrazioni RLS.
- Le mock data nel WorkLogHistoryPage vanno rimosse **dopo** che il flusso reale funziona, non prima (altrimenti la pagina diventa vuota durante lo sviluppo).
