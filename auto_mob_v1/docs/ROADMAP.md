# AutoMob — Roadmap operativa

> Documento vivo. Per ogni punto, man mano che decidiamo, scriviamo qui **le scelte prese** (sezione "Decisioni").
> Aggiornato durante le sessioni di lavoro. Ultima revisione: 2026-06-17.

Legenda stato: 🔲 da fare · 🛠️ in corso · ✅ fatto

---

## 1. ✅ Aggiunta di un lavoro (WorkLog write-path)

**Obiettivo:** completare e rendere funzionante il salvataggio di un intervento di manutenzione.

**Stato verificato (2026-06-16):**
- Catena Dart COMPLETA: `AddWorkLogPopUp` → `OnSubmitEvent` → `CreateWorkLog` (usecase) → `WorklogRepositoryImpl` → `WorklogRemoteDataSourceImpl` → `rpc('crea_sessione_manutenzione', {p_payload})`.
- ❌ La RPC `crea_sessione_manutenzione` **NON esiste sul DB** → il salvataggio fallisce. È il blocker principale.
- Il payload Dart è "piatto": **1 record + 1 item (un solo `type`) + N parts**.
- `parts.id` è `bigint` 1-95 (combacia con la mappa `kParts` hardcoded). Il doc DB su questo è obsoleto.

**Payload attuale inviato da Dart (`worklog_remote_data_source.dart`):**
```jsonc
{
  "vehicle_id": "uuid",
  "type": "tagliando|distribuzione|pneumatici_cambio|revisione|pneumatici_inversione|altro",
  "custom_name": "string|null",   // obbligatorio solo se type=altro
  "service_km": 50000,
  "service_date": "2026-06-16",
  "notes": "string|null",
  "interval_km": 15000,           // può essere null/0 → niente next_service_km
  "parts": [
    { "part_id": 15, "quantity": 1, "unit_price": 12.5, "notes": null }
  ]
}
```

**Bug noti lato UI da sistemare in questo punto:**
- Il campo Note (`_noteController`) non fa dispatch → `state.note` resta vuoto.
- Il DatePicker (`_dateController`) non fa dispatch → `service_date` è sempre `DateTime.now()`.

### Decisioni (2026-06-16)

**Modello dati:**
- **1 salvataggio = 1 `maintenance_record` + 1 `maintenance_item`** (un item può avere N parti). Niente multi-item per
  non complicare la UI di aggiunta. La tabella `maintenance_records` resta come contenitore "magro" (FK obbligatoria).
- Alla RPC arriva: `vehicle_id`, dati dell'item (`type`, `custom_name`, `service_km`, `service_date`, `notes`,
  `interval_km`), e la **lista di parti**.

**Flusso RPC `crea_sessione_manutenzione(p_payload jsonb)`** (confermato):
1. Validazione: caller = `owner_id` del veicolo (mecc. rimandato al punto 3).
2. INSERT `maintenance_records` (vehicle_id, service_date, notes) → ottengo `record_id`.
3. INSERT `maintenance_items` (record_id, type, custom_name, service_km, service_date,
   `next_service_km` = service_km + interval_km se interval_km > 0, notes) → ottengo `item_id`.
4. UPDATE `vehicles.km_current` ai km in input (`service_km`) — con guardia anti-regressione (no km < attuale).
5. INSERT N `maintenance_item_parts` con l'`item_id`.
- `SECURITY INVOKER`, execute revocato ad `anon`. SQL commentato in italiano.

**Pulizia/refactor decisi:**
- `kParts` (95 voci) centralizzata in **un solo file** `core/constants/parts_catalog.dart` (mirror del catalogo
  `parts` del DB, `id` bigint 1-95). Rimosse le 3 copie sparse.
- Entità `WorkLogItem` ripulita: è una **parte selezionata** → solo `partId, quantity, unitPrice, note`.
  Rimossi `id` (duplicava `partId` → causa del "id condiviso poco robusto"), `km`, `date`, `notes`
  (appartengono all'item, non alla parte). Matching ovunque su `partId`.
- Eliminati codici morti: `MaintenanceEntity.dart` (mai usato) e `WorkLogItemModel` (mai istanziato, da
  ricreare allineato nel punto 6).

**Bug UI sistemati in questo punto:**
- Dispatch del campo Note e del DatePicker collegati al bloc (prima persi). `service_date` ora reale, default = oggi.
- `AmSparePartCard`: tap sulla card chiude l'espansione (tranne su elementi interattivi).

### ✅ FATTO (2026-06-16) — verificato end-to-end

**DB (migration `automob_v4_worklog_rpc_e_storico_km` + `automob_v4_blinda_trigger_storico`):**
- RPC `crea_sessione_manutenzione(p_payload jsonb)` `SECURITY INVOKER`, execute solo `authenticated`.
  Flusso: ownership check → record → item → UPDATE veicolo (`km_current = GREATEST(...)` + intervallo per
  tipo) → N item_parts. **NB:** `maintenance_items` NON ha `next_service_km` → il "richiamo" si salva
  sull'intervallo del veicolo (`tagliando_interval_km`, `distribution_intervall_km`,
  `tire_change_interval_km`, `tire_rotation_interval_km`); `revisione`/`altro` non toccano intervalli.
- **Storico km veicolo**: nuova tabella append-only `vehicle_history(id, vehicle_id, km, event_type, created_at)`
  con `event_type ∈ {creazione, manutenzione, aggiornamento_km}`. Riempita da **trigger**
  `trg_storico_km` (`AFTER INSERT OR UPDATE OF km_current ON vehicles`) → funzione `registra_storico_km`
  `SECURITY DEFINER` (il client non può scrivere/falsificare lo storico). Il tipo evento è passato al
  trigger via `set_config('app.tipo_evento_km', ...)`. La creazione veicolo è loggata in automatico → la
  RPC `crea_veicolo_con_storico` NON è stata toccata.
- **RLS accese** dove mancavano: `maintenance_item_parts` (+ policy insert owner) e `parts` (sola lettura).
- Test transazionale OK: 1 item, 2 parti, km 8000→13000 (GREATEST), storico `manutenzione`, intervallo→20000.

**Dart:** la catena era già completa e ora combacia col DB. Refactor di pulizia applicato (vedi sopra).

**⚠️ Trovato ma NON di questo punto:** `mechanics` ha policy RLS ma **RLS è spenta** (advisor ERROR).
Da sistemare nel **punto 3** (entità meccanico).

---

## 2. ✅ Logica di update dei KM

**Obiettivo:** la query/flow di aggiornamento dei km del veicolo.

### ✅ FATTO (2026-06-16) — verificato end-to-end

**DB (migration `automob_v4_rpc_aggiorna_km_veicolo`):**
- RPC `aggiorna_km_veicolo(p_vehicle_id, p_nuovo_km)` `SECURITY INVOKER`, execute solo `authenticated`:
  ownership check, km non negativi, `GREATEST` (mai indietro). Il trigger `trg_storico_km` logga
  automaticamente `aggiornamento_km`. Test OK: regressione bloccata (8000 tenuto), salita a 11000, storico ok.

**Dart:**
- Data-layer: `VehicleRemoteDataSource.updateKm` → repo → usecase `UpdateVehicleKm` → DI.
- `KmUpdateCubit` (loading/success/failure) in `vehicle/presentation/provider`.
- `KmUpdatePopUp` ora **salva davvero**: riceve `vehicleId` via route, mostra i km attuali, valida in tempo
  reale `nuovo > attuali` (bottone attivo solo se valido), spinner durante il salvataggio, snackbar su errore.
- **Refresh dashboard**: la modale ritorna `true` → `HomeView` ricarica (`LoadDashboardData`). Stesso meccanismo
  applicato anche al salvataggio lavoro (punto 1).

**Anche per il pop-up lavoro (richiesta utente):**
- I km del veicolo sono **passati al pop-up** (`currentKm` via route): il campo è pre-compilato e mostra gli
  attuali; validazione `km lavoro >= attuali` (real-time + hard-block al submit nel bloc via `vehicleKm`).
- Aggiunti più valori al dropdown "Richiamo tra" (fino a 150000).

**Scelta:** nel pop-up lavoro il check è `>=` (il lavoro può essere ai km attuali), nella modale KM è `>`
(stai dichiarando un chilometraggio nuovo/maggiore). Entrambi impediscono la regressione.

---

## 3. 🔲 Entità Meccanico + collegamento veicolo↔meccanico

**Obiettivo:** in fase di creazione veicolo, se è presente un codice meccanico (not null), creare il
collegamento nella tabella ponte `vehicle_mechanics`.

**Note:**
- `codiceMeccanico` è già raccolto nel wizard ma NON usato.
- Tabella ponte `vehicle_mechanics` già esistente.
- Serve lookup meccanico per codice + RLS meccanico.

### Decisioni
_(da compilare)_

---

## 4. 🔲 Caso d'uso di Logout

**Obiettivo:** implementare il logout (usecase + wiring nella UI/profilo).

### Decisioni
_(da compilare)_

---

## 5. 🔲 Gestione stati di caricamento / transizione pagine / errori

**Obiettivo:** uniformare loading, transizioni e gestione errori (show dialog) su tutta l'app.

### Decisioni
_(da compilare)_

---

## 6. 🛠️ Pagina WorkLog History (storico lavori)

**Obiettivo:** tutta da progettare.
- Recuperare la lista veicoli in formato `id/nome`.
- Recuperare tutti i lavori di un veicolo.
- **Stream/paginazione**: caricare N elementi alla volta, swipe-up = carica altri, swipe-down (pull-to-refresh) = ricarica.

### Decisioni (2026-06-17)

**Architettura:** `WorkLogHistoryBloc` DEDICATO (separato dal `WorkLogBloc` di creazione).
Stato unico con due liste: `vehicles` (dropdown, caricata una volta) + `works` (lavori del
veicolo selezionato, accumulata e paginata). Flag chiave: `isLoadingMore`, `hasReachedMax`.

**Lettura (no RPC, no vista):** select dirette filtrate dalla RLS.
- Veicoli: `vehicles` (id, plate, brand, model, km_current) filtrato per owner.
- Lavori: `maintenance_items` con embed `maintenance_records!inner(vehicle_id, mechanic_id)`
  → filtro su `vehicle_id`, `has_workshop = mechanic_id != null`. Ordine
  `service_date desc, created_at desc` (tie-breaker stabile per la paginazione).
- Scartata la vista `vista_storico_lavori`: utile per uniformità ma non necessaria. Niente migration.

**Paginazione offset (`.range(from,to)`):** `pageSize = 20`, `from = works.length`.
Fetta < 20 ⇒ `hasReachedMax`. `.range` oltre la fine NON va in errore (torna meno righe/vuoto).
3 guardie anti doppio-load: `isLoadingMore`, `hasReachedMax`, transformer `droppable()` su
`LoadMore` (pacchetto `bloc_concurrency`). `ScrollController` lancia `LoadMore` a ~300px dal fondo.
NB dati attuali: max 8 lavori/veicolo (< 20) ⇒ per vedere il load-more abbassare `pageSize`.

**Flusso pop-up:** `AmStatusDialog` riutilizzabile in `core/widgets/Dialog` (icona+colore+messaggio
+N azioni, stile iOS vetro). Mostrato via `BlocListener` (side-effect, mai nel builder).
- loading → spinner; error → Riprova(rilancia)/Chiudi(→home); 0 veicoli → Aggiungi/Chiudi.
- **0 lavori ≠ pop-up**: stato vuoto INLINE (`_EmptyWorks`), l'utente resta sul dropdown.
- Cambio veicolo: NON ripropone il pop-up, spinner inline. Refresh post-aggiunta via
  `ReloadCurrent` (mantiene la selezione).

### ✅ FATTO (2026-06-17)
Entità `VehicleOption`/`WorkLogRow` + model, datasource (`getVehicleOptions`/`getWorks`), repo,
usecase (`GetVehicleOptions`/`GetVehicleWorks`), `WorkLogHistoryBloc` (eventi `LoadInitial`,
`VehicleChanged`, `LoadMore`, `Retry`, `ReloadCurrent`), DI, `AmStatusDialog`, pagina riscritta
(dropdown dinamico + lista paginata + pop-up). Analyzer pulito (solo info di stile pre-esistenti).

### 6.1 🔲 Pull-to-refresh anche nella Home
- Swipe-down nella Home ricarica i dati.
- Togliere il ricaricamento automatico ad ogni ingresso nella Home: caricare i dati SOLO all'avvio e poi su pull-to-refresh.
- Serve schermata di caricamento + show dialog di errore.
- _(Aggiungere pull-to-refresh anche alla pagina storico, riusando `AmStatusDialog`.)_

---

## 7. ✅ RISOLTO (2026-07-11) — crash all'apertura del pop-up "Aggiungi lavoro" (2026-06-17)

**Fix applicati:** campo "Nome intervento" avvolto in `Row` (fix puntuale sotto) + bottone
INDIETRO: animata solo la larghezza con altezza fissa dentro `ClipRect`+`OverflowBox`.
Resta aperto solo il **fix di fondo** (togliere l'`Expanded` nascosto dai widget input),
da valutare nel rework dei pop-up (punto 8.2).

**Sintomo:** aprendo il pop-up di registrazione lavoro dalla pagina WorkLog → **schermata grigia**.
In console (il primo errore, NON il `DiagnosticsProperty<void>` che è solo rumore secondario):
`type 'BoxParentData' is not a subtype of type 'FlexParentData' in type cast` (`Flexible.applyParentData`).

**Causa:** `AmTextField`, `AmDatePickerField` e `AmDropdown` hanno come **root un `Expanded`**
→ vanno usati SOLO dentro un `Row`/`Column`. Nel ramo `type == altro` di `FirstPageAddWork`
(`AddWorkLogPopUp.dart` ~riga 312) il campo "Nome intervento" è avvolto in un **`Padding`** (non-Flex):
`Padding(child: AmTextField(...))` → l'`Expanded` trova un genitore `RenderPadding` (`BoxParentData`)
→ cast fallisce. Si apre SEMPRE con `EnumPopUp.altro` dalla pagina worklog ⇒ crash garantito.

**Fix puntuale (1 riga):** avvolgere quel campo in un `Row` come tutti gli altri:
```dart
return Padding(
  padding: const EdgeInsets.only(top: 24),
  child: Row(children: [ AmTextField(...) ]),
);
```
**Fix di fondo (debito tecnico):** è fragile che questi widget ritornino `Expanded` di nascosto.
Meglio rimuovere l'`Expanded` interno e lasciare che sia il chiamante a decidere (`Expanded`/`Flexible`
solo quando serve davvero, dentro un Flex). Da valutare nel rework dei pop-up (punto 9).

**Bug minore correlato (stesso file):** il bottone "INDIETRO" sulla pagina 0 viene messo in un
`AnimatedContainer` con `width:0, height:0` → un `OutlinedButton` forzato in un box 0×0 genera
overflow ad ogni frame. Animare solo la larghezza tenendo l'altezza fissa (+ `ClipRect`/`OverflowBox`).

---

## 8. 🔲 Backlog UI/UX (sessione 2026-06-17)

Lista raccolta dall'utente. NON ancora in sviluppo — solo registrata.

1. **Dropdown pull-down veicolo (`AmPullDownLG`) — la lista non segue lo scroll.**
   Il menu si apre con `showGeneralDialog` e disegna la lista in un `Positioned` calcolato UNA
   volta sulle coordinate del trigger (`_misuraTrigger`). Se la pagina sotto scrolla, il trigger si
   muove ma la lista resta fissa nel punto iniziale. Serve far seguire la lista al trigger (o chiudere
   il menu allo scroll). Valutare `CompositedTransformTarget`/`CompositedTransformFollower` +
   `LayerLink`, oppure un `OverlayPortal` ancorato.

2. **Pop-up → pagine full-screen.** Non piace il layout attuale a `ModalBottomSheet`. Convertire sia
   **Aggiungi veicolo** sia **Aggiungi lavoro** in vere pagine (route dedicate, transizione di pagina).
   Occasione giusta per sistemare il debito tecnico dell'`Expanded` nascosto (vedi punto 7).

3. **Foto veicolo.**
   - Poter aggiungere/cambiare la foto **toccando la card del veicolo** (non solo in registrazione).
   - Oggi la foto si può prendere solo dalla **galleria** in fase di registrazione → aggiungere anche
     **fotocamera** (sorgente a scelta).

4. **Tema chiaro/scuro.** Switch per attivare/disattivare il tema scuro (persistere la scelta).

5. **Bottom bar.** Rework della bottom bar + migliorare le **transizioni** al cambio tab.

6. **WorkLog History — card lavori.**
   - Espansione delle card lavoro (tap → dettaglio).
   - Miglioramento UI delle card lavoro.

7. **Card veicolo.** Miglioramento UI della card veicolo.

### Stato attuale dello switch veicolo (per riferimento, vedi spiegazione in chat 2026-06-17)
- Trigger: `AmPullDownLG` nell'AppBar di `WorkLogHistoryPage` (`_VehicleDropdown`).
- Al tap su una voce → `VehicleChanged(v.id)` + `Navigator.maybePop()` (chiude il menu).
- `WorkLogHistoryBloc._onVehicleChanged`: se id uguale a quello attuale → no-op; altrimenti svuota
  `works`, setta `isLoadingMore` (spinner inline, NIENTE pop-up a tutto schermo), ricarica pagina 0.
- Refresh dopo aggiunta lavoro: `ReloadCurrent` (mantiene la selezione).

---
</content>
</invoke>
