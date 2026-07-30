# AutoMob — Project Specification

Documento di specifica per il progetto AutoMob. Descrive il prodotto, l'architettura, le entità di dominio, le feature, i flussi, le regole. Non contiene codice eseguibile né SQL: serve a chi deve capire **cosa** costruire e **perché**, prima di scrivere qualunque riga.

---

## 1. Prodotto

### Cos'è
AutoMob è un'app mobile per la gestione della manutenzione di veicoli privati. L'utente registra una o più auto, traccia gli interventi eseguiti, riceve KPI calcolati sullo stato di ogni manutenzione (tagliando, distribuzione, revisione, gomme), pianifica interventi futuri e gestisce un'anagrafica di meccanici/gommisti/centri revisione.

### Funzionalità V1
- Autenticazione: email/password, Google, Apple
- Wizard di registrazione veicolo a 4 step con persistenza del progresso
- Dashboard multi-veicolo con swipe tra auto, KPI a donut, interventi pianificati, ultimi lavori
- Storico lavori con filtri, dettaglio, costi
- Aggiunta lavoro con dropdown a 3 livelli (tracked/standard/custom) e selezione componenti
- Pianificazione interventi futuri
- Anagrafica fornitori (meccanici, gommisti, centri revisione) con codici di collegamento
- Profilo utente con piano free/premium

### Fuori scope V1
- Sync bidirezionale offline
- Backup foto su cloud
- Multi-tenancy B2B (meccanico che vede le auto dei clienti)
- Notifiche push
- Export PDF/Excel dello storico
- Statistiche aggregate sui costi

---

## 2. Stack tecnologico

| Livello | Scelta | Motivo |
|---|---|---|
| Framework | Flutter (stable) | Cross-platform iOS+Android con un solo codebase |
| Linguaggio | Dart 3.x | Sealed class e pattern matching essenziali per l'architettura |
| State management | flutter_bloc | Pattern BLoC per separazione UI/logica e testabilità |
| Dependency injection | get_it | Service locator semplice, zero boilerplate |
| Navigation | go_router | Navigazione dichiarativa, deep linking, shell route per bottom nav |
| Backend | Supabase | Postgres managed + Auth + Storage + RLS in un solo servizio |
| Persistenza locale | shared_preferences + filesystem | Solo wizard draft e foto veicolo |
| Error handling | fpdart (Either) | Type-safe alternative alle eccezioni |
| Data classes | freezed (consigliato) | copyWith, equality, immutabilità automatici |
| Testing | bloc_test + mocktail | Standard di settore per testare i BLoC |

### Note sullo stack
**Online-only**: nessun layer di sync, nessuna cache locale dei dati strutturati. Senza connessione l'app mostra schermata offline. Eccezione: il wizard veicolo persiste step-per-step in SharedPreferences per non perdere dati durante la compilazione.

**Foto veicolo solo locale**: salvate nel filesystem del device. Mai su Supabase Storage. Se l'utente cambia device, perde le foto — è una scelta esplicita.

**Fatture**: nel filesystem device per utenti free. Su Supabase Storage solo per utenti premium (feature da implementare con il piano premium).

---

## 3. Architettura

### Pattern: Clean Architecture per feature
Ogni feature è una cartella autonoma con tre layer:
- **domain/** — entità, contratti dei repository (interfacce), use case. Layer puro, zero dipendenze da framework esterni.
- **data/** — implementazioni dei repository, datasource (Supabase, filesystem), DTO/model con serializzazione JSON.
- **presentation/** — BLoC (eventi/stati), pagine, widget specifici.

Il layer `domain/` è **pubblico** (importabile da altre feature), `data/` e `presentation/` sono **privati** (mai importati da fuori).

### Le 6 feature
- **auth** — login, signup, logout, gestione sessione
- **vehicle** — anagrafica veicolo, wizard registrazione, foto, aggiornamento km
- **work_log** — storico lavori, aggiunta lavoro, pianificazioni, dettaglio
- **dashboard** — home con KPI, swipe tra veicoli, timeline interventi
- **service_provider** — anagrafica meccanici/gommisti/centri revisione
- **profile** — profilo utente, piano free/premium, settings

Più due moduli trasversali:
- **core/** — theme, DI, sealed types condivisi, widget riutilizzabili, gestione errori
- **shell/** — AppWrapper con bottom navigation
- **router/** — configurazione GoRouter centralizzata

### Grafo delle dipendenze (DAG)
Le dipendenze tra feature vanno in una sola direzione, mai indietro. Si forma un grafo aciclico:

- `auth`, `vehicle`, `service_provider`, `profile` sono foglie — non dipendono da nessuno
- `work_log` dipende da `vehicle` (riferimento per FK) e `service_provider` (dropdown nel form)
- `dashboard` dipende da `vehicle`, `work_log`, e opzionalmente `profile`
- **Nessuna feature può dipendere da `dashboard`**

Questa regola previene strutturalmente le dipendenze circolari. Se una feature di base avesse bisogno di importare qualcosa dalla dashboard, è il segnale che la cosa va spostata: o nel core (se è condivisa) o nella dashboard stessa (se è specifica).

### Regola di accesso cross-feature
Una feature A può importare da una feature B **solo** dal layer `domain/`. Mai dal `data/`, mai dal `presentation/`. In pratica: si importano entità ed interfacce di repository, mai DTO/Model né BLoC né widget.

### Comunicazione cross-feature
I BLoC di feature diverse non si parlano mai direttamente. La comunicazione avviene esclusivamente via **router**: una feature lancia push verso una rotta, l'altra feature gestisce il flusso col suo BLoC, e al ritorno fa pop con un risultato. Il chiamante riceve il risultato e decide cosa fare.

Questo pattern garantisce zero accoppiamento di presentation e si vede esplicitamente nel codice (chi chiama cosa è scritto nelle rotte).

### Regola di scrittura
Ogni feature scrive **solo sul proprio repository**. Eccezione: la `dashboard` può orchestrare scritture cross-feature delegando ai use case delle rispettive feature (es. dopo aver aggiunto un lavoro, aggiorna i km del veicolo chiamando UpdateVehicleKm di vehicle).

---

## 4. Decisioni architetturali principali

### D1 — Online-only V1
Niente sync bidirezionale. Senza connessione, l'app non funziona. Mitigazione: wizard veicolo salvato a ogni step in SharedPreferences.

### D2 — UUID v4 client-side
Tutte le primary key sono UUID generati dall'app prima dell'INSERT. Mai auto-increment. Permette update ottimistici nella UI senza attendere la risposta del server.

### D3 — Valori derivabili mai persistiti
I KPI (percentuali, status, km alla scadenza) sono calcolati al volo dai use case. Non esistono colonne che li memorizzano. La query "ultimo intervento per tipo" si risolve con ordinamento decrescente sulla data di esecuzione, mai con flag is_last.

### D4 — Invarianti difese anche dal DB
Ogni invariante critica del dominio è replicata come constraint Postgres. Doppio livello: validazione Dart + CHECK SQL. Se domani uno script bypassasse il repository, il database rifiuta dati incoerenti.

### D5 — Row Level Security obbligatoria
Ogni tabella ha policy RLS attive dall'inizio. Senza, chiunque con la chiave anon Supabase potrebbe leggere dati di altri utenti. La RLS si progetta insieme allo schema, non si aggiunge dopo.

### D6 — Money in centesimi (interi, mai float)
Tutti gli importi sono interi in centesimi più un campo testo per la valuta (ISO 4217). Mai double/float per soldi: gli arrotondamenti floating point sono un classico bug impossibile da debuggare.

### D7 — ServiceType come tagged union a 3 livelli
Il tipo di lavoro è un sealed type con tre varianti:
- **tracked** — i 5 lavori principali con KPI dedicato (tagliando, distribuzione, revisione, cambioGomme, inversioneGomme)
- **standard** — lista chiusa di altri lavori comuni dal libretto meccanico (cambioOlio, candele, pastiglieFreni, ecc.), senza KPI
- **custom** — stringa libera, ultima risorsa

Le liste tracked e standard vivono nell'app come enum Dart, **non in DB**. Cambiarle = release dell'app, non migrazione.

### D8 — Componenti del WorkLog come array JSONB
La lista dei pezzi sostituiti in un intervento è serializzata come JSONB in una colonna del work_log. Non è una tabella separata. Motivo: i componenti sono attributo atomico del lavoro, non hanno vita propria, non si aggregano (almeno in V1).

### D9 — Nessun trigger Postgres
Le regole di business stanno tutte nel codice Dart, mai nei trigger DB. La dashboard orchestra le scritture cross-feature delegando ai use case. Se domani serve "aggiornare km dopo un lavoro", la dashboard chiama il use case di vehicle, non un trigger SQL. Mantiene tutta la logica leggibile nel codice.

### D10 — La dashboard è orchestratrice, non scrittrice
La dashboard non possiede entità persistite. Legge da repository altrui, calcola KPI in memoria, mostra. Quando deve scrivere (es. aggiornare km dopo un lavoro), riceve il dato dal modale chiamato e delega al use case della feature competente.

---

## 5. Entità di dominio

### Entità persistite (5)

**AppUser** — profilo utente
- Identificativo, nome visualizzato, avatar, piano (free/premium), lingua
- Distinto dall'AuthUser di Supabase (che contiene solo credenziali)
- Stesso ID dell'AuthUser per coerenza referenziale

**Vehicle** — il veicolo
- Identificativo, proprietario, marca, modello, anno, targa, alimentazione, cilindrata, cavalli, km attuali
- Contiene MaintenanceIntervals come value object embedded (in JSONB sul DB) — gli intervalli personalizzati per quel veicolo
- Foto referenziata solo come path filesystem locale, mai nel DB

**WorkLog** — intervento eseguito (immutabile concettualmente)
- Identificativo, veicolo di appartenenza, fornitore opzionale
- Tipo del servizio (sealed: tracked/standard/custom)
- Data, km al momento del lavoro, costo (centesimi + valuta), descrizione libera
- Lista componenti sostituiti (JSONB embedded)
- Path della fattura (locale per free, Storage per premium)

**PlannedMaintenance** — pianificazione futura modificabile
- Identificativo, veicolo, tipo del servizio (stesso sealed di WorkLog)
- Data programmata e/o km target (almeno uno dei due deve essere valorizzato)
- Note libere

**ServiceProvider** — anagrafica fornitore
- Identificativo, proprietario, tipo (mechanic/tireShop/inspectionCenter)
- Nome, codice di collegamento (per futuro B2B), telefono, indirizzo
- Flag is_connected (sempre false in V1, predispone V2)

### Entità calcolate (non persistite)

**MaintenanceKPI** — output di use case, mostrato nei donut
- Tipo di servizio, percentuale rimanente, status (ottimale/buono/inScadenza/urgente/scaduto)
- Prossima scadenza (km o data), data e km dell'ultimo intervento
- Stringa human-readable della motivazione ("mancano 1.200 km")

**VehicleDashboard** — view model composito della home
- Un Vehicle, la sua lista di KPI (uno per tracked kind), gli ultimi 3 WorkLog, le prossime 3 pianificazioni
- Composto dal use case GetVehicleDashboard, mai persistito

### Value objects condivisi
- **LicensePlate** — wrapper su String con validazione targa italiana
- **Kilometers** — wrapper su intero, invariante: ≥ 0
- **Money** — amount in centesimi (intero) + currency (enum ISO 4217)
- **MaintenanceIntervals** — gli intervalli per ogni TrackedServiceKind di un veicolo

### Sealed types condivisi (in core/)
- **ServiceType** (tracked/standard/custom)
- **TrackedServiceKind** (5 valori)
- **StandardServiceKind** (~20 valori dal libretto meccanico)
- **ComponentKind** (~20 voci dal libretto)
- **FuelType** (gasoline, diesel, hybrid, phev, electric, lpg, cng, other)
- **ProviderType** (mechanic, tireShop, inspectionCenter)
- **Plan** (free, premium)
- **MaintenanceStatus** (ottimale, buono, inScadenza, urgente, scaduto) — derivato

---

## 6. Schema database (struttura)

Cinque tabelle applicative su Supabase Postgres. Nessuna logica nei trigger oltre agli updated_at automatici.

### Tabelle e relazioni

**app_user** ← uno-a-uno con auth.users di Supabase

**vehicle** ← N-a-1 con app_user (cascade su delete)

**work_log** ← N-a-1 con vehicle (cascade), N-a-0..1 con service_provider (set null su delete: si preserva lo storico se cancelli un meccanico)

**planned_maintenance** ← N-a-1 con vehicle (cascade)

**service_provider** ← N-a-1 con app_user (cascade)

### Caratteristiche dello schema

- **Tutte le PK sono UUID v4** generate client-side
- **JSONB per dati embedded**: maintenance_intervals nel veicolo e components nel work_log. Sono attributi atomici delle entità, non entità separate. Postgres tratta JSONB come tipo navigabile: non viola 1NF moderno e supporta query/indici.
- **CHECK constraint per le invarianti del dominio**:
    - km non negativi
    - service_kind coerente con kind_code/custom_label (esattamente uno dei due valorizzato in base al kind)
    - planned_maintenance ha almeno uno tra scheduled_date e target_km
    - cost_currency è codice ISO 4217 valido
- **UNIQUE su (user_id, plate)** — un utente non può registrare due volte la stessa targa
- **Indici dedicati** per le query principali (ultimo lavoro per tipo, scroll storico, prossimi pianificati)
- **RLS policy** su ogni tabella basate sull'identità dell'utente autenticato — l'utente vede solo i propri dati

### Cosa NON c'è nel DB
- Nessuna tabella maintenance_rule (gli intervalli vivono embedded nel veicolo)
- Nessuna tabella kpi (calcolati runtime)
- Nessuna tabella di sessioni/draft (vive in SharedPreferences locale)
- Nessuna colonna photo_url sul vehicle (la foto è solo locale)
- Nessun flag is_last sui work_log (l'ordinamento è la fonte di verità)

---

## 7. Use case per feature

### auth
- LoginWithEmail
- LoginWithGoogle
- LoginWithApple
- SignupWithEmail
- Logout
- CheckSession (controllo all'avvio app)
- EnsureProfileExists (crea AppUser se non esiste, dopo il primo login)

### vehicle
- RegisterVehicle (salva veicolo + foto al termine del wizard)
- UpdateVehicleKm
- DeleteVehicle
- GetVehicleById
- GetAllVehiclesByUser
- SaveWizardDraft (persiste step parziale)
- LoadWizardDraft (recupera all'apertura del wizard)
- ClearWizardDraft

### work_log
- AddWorkLog
- UpdateWorkLog
- DeleteWorkLog
- GetWorkLogHistory (paginato, con filtri opzionali)
- GetLatestByType (ultimo lavoro per ogni tipo tracked, usato dalla dashboard)
- AddPlannedMaintenance
- UpdatePlannedMaintenance
- DeletePlannedMaintenance
- GetUpcomingPlanned (prossime pianificazioni per veicolo)

### dashboard
- GetVehicleDashboard (use case composito che chiama VehicleRepo + WorkLogRepo + calcola KPI)
- CalculateMaintenanceKPI (domain service puro, senza repository)

### service_provider
- AddProvider
- UpdateProvider
- DeleteProvider
- GetAllProvidersByUser (con filtro per tipo)
- GetProviderById

### profile
- GetProfile
- UpdateProfile
- UpgradeToPremium
- DowngradeToFree

---

## 8. UI/UX

### Struttura di navigazione
- **Splash/Auth check** → schermata iniziale che decide se andare al login o alla home
- **Login/Signup** → schermate piene, fuori dal wrapper
- **AppWrapper** (Scaffold con bottom navigation a 4 tab) → contenitore di tutte le pagine principali post-login
    - Tab "Veicoli" → DashboardPage (la home)
    - Tab "Storico lavori " → WorkLogListPage
    - Tab "Servizi" → ServiceProviderPage
    - Tab "Profilo" → ProfilePage
- **Modali e pagine secondarie** (push da qualunque schermata) → wizard veicolo, aggiungi lavoro, aggiorna km, dettaglio lavoro

La bottom nav resta sempre visibile dentro l'app loggata, anche durante i caricamenti delle singole pagine. La struttura usa StatefulShellRoute di GoRouter così ogni tab mantiene il proprio stack di navigazione indipendente.

### Schermata Dashboard (tab Veicoli)
- Header con officina di riferimento (se collegata) + pulsante "+" per aggiungere veicolo
- Card veicolo con foto, modello, km totali — **swipeable** orizzontalmente per cambiare auto se l'utente ne ha più di una
- Griglia di donut KPI (4-5 a seconda dell'alimentazione) per il veicolo attualmente visualizzato: tagliando, distribuzione, revisione, cambio gomme, inversione gomme. Ogni donut con percentuale, status colorato, ultimo intervento, prossima scadenza
- Sezione "Interventi pianificati" con timeline dei prossimi 3
- Un FAB aggiorna che se cliccato espande altri   FAB : "Aggiorna KM" +  "Aggiorna tagliando"+ "Aggiorna Distribuzione" + "Cambio gomme" + "Revisione" sul veicolo corrente
 ***i fab aggiorna tagliando e aggiorna revsione aprono lo stesso pop up modale di aggiunta lavoro ma con il servizio type gai selezionato "Revisone,Tagliando"***

### Schermata Storico (tab Lavori)
- Header con statistiche: totale interventi, spesa totale, ultimo km, stato salute generale
- Lista cronologica dei lavori del veicolo selezionato
- Filtri per tipo e periodo
- FAB "Aggiungi lavoro"
- Tap su un lavoro → pagina dettaglio

### Schermata Servizi
- Selezione del veicolo
- Tre campi/sezioni: codice meccanico, codice gommista, codice centro revisione
- Gestione anagrafica: aggiungere, modificare, rimuovere fornitori personali

### Schermata Profilo
- Dati anagrafici, avatar, piano corrente
- Pulsante upgrade premium
- Settings app (lingua, tema futuro)
- Logout

### Modali principali

**Wizard Registra Veicolo (4 step)**
- Step 1 — Vehicle Information: marca, modello, anno, targa
- Step 2 — Engine & Performance: alimentazione, cilindrata, cavalli, km attuali
- Step 3 — Maintenance Logs: ultimi tagliando/distribuzione/cambio gomme noti
- Step 4 — Deadlines & Compliance: scadenza revisione, foto veicolo
- Salvataggio progressivo in SharedPreferences a ogni step
- Bottoni Indietro/Avanti, ultimo step ha "Registra"

**Aggiorna KM**
- Selezione veicolo (pre-selezionato)
- Visualizzazione km attuali → nuovo valore con freccia
- Input numerico con validazione "non inferiore al km attuale"
- Pulsante Aggiorna KM

**Aggiungi Lavoro**
- Selezione veicolo (pre-selezionato dalla provenienza)
- Dropdown tipo: prima sezione "Principali" (5 tracked), seconda "Altri" (standard), ultima "Altro..." (custom con input testo)
- Selezione componenti sostituiti (multi-select da dropdown standard + custom)
- Data, km al momento del lavoro, costo, fornitore (opzionale), descrizione
- Validazione: data non futura, costo ≥ 0, km ≥ km attuali del veicolo
- Pulsante Salva
- Al ritorno, ritorna al chiamante un oggetto WorkLogResult con km del lavoro

**Aggiorna Pneumatici** (caso speciale di lavoro)
- tab selzionabile con due voci :Toggle Cambio gomme / Inversione gomme
- Aggiornamento km sempre obbligatorio

**Aggiorna Revisione**
- Data revisione (con shortcut: oggi, ieri, scorso mese)
- Calcolo automatico prossima scadenza

### Tono visivo
Dark theme dominante con accenti arancioni per elementi attivi (FAB, donut critici, pulsanti primari). Blu per elementi in stato normale. Tipografia bold per i numeri (km, costi, percentuali) e regular per le label. Spaziature generose, card con bordi arrotondati.

---

## 9. Catalogo errori (Failure)

L'app gestisce gli errori in modo type-safe via Either<Failure, T> ritornato dai repository. Ogni Failure ha un messaggio human-readable mostrato all'utente. Lista delle failure previste:

| Failure | Quando si verifica | Messaggio utente |
|---|---|---|
| NetworkFailure | Connessione assente, timeout, DNS unreachable | "Connessione assente. Controlla la rete e riprova." |
| ServerFailure | Errore Supabase non specifico, status 5xx | "Si è verificato un errore. Riprova tra qualche istante." |
| NotFoundFailure | Risorsa cercata non esiste (es. veicolo eliminato) | "Risorsa non trovata." |
| ValidationFailure | Input non valido a livello dominio (es. targa malformata) | Messaggio specifico (es. "Targa non valida") |
| AuthFailure | Credenziali errate, sessione scaduta, OAuth annullato | Specifico (es. "Email o password errati") |
| PermissionFailure | RLS Postgres rifiuta l'accesso (non dovrebbe accadere se la logica è corretta) | "Non hai il permesso di accedere a questa risorsa." |
| DuplicateFailure | Vincolo UNIQUE violato (es. targa già registrata) | "Questa targa è già registrata." |
| StorageFailure | Errore filesystem locale (foto, draft) | "Impossibile salvare il file sul dispositivo." |
| AuthCancelledFailure | L'utente ha chiuso il flow OAuth prima di completarlo | "Accesso annullato." |
| EmailAlreadyInUseFailure | Signup con email esistente | "Questa email è già registrata. Effettua il login." |
| WeakPasswordFailure | Password troppo debole al signup | "La password è troppo debole. Usa almeno 8 caratteri." |
| BusinessRuleFailure | Violazione di regola di dominio (es. km nuovi minori dei vecchi) | Specifico (es. "I km non possono diminuire") |

Le failure sono **sealed class** in core/error/failure.dart. Il BLoC riceve l'Either dal use case, fa fold, ed emette uno stato XxxError(message) se Left. La UI mostra il messaggio in uno snackbar o in un widget di errore con pulsante "Riprova".

---

## 10. Convenzioni di codice (regole vincolanti)

Ogni regola è un divieto o un obbligo. Nessuna è discrezionale.

### Sintattiche
1. **Sealed class** per tutti gli eventi e stati BLoC. Mai classi astratte semplici, mai enum.
2. **Switch esaustivo** nella UI per consumare gli stati. Mai catene di if con type check.
3. **const** su ogni widget i cui parametri sono noti a compile time.
4. **Mai setState** in tutto il progetto. Tutta la gestione di stato passa per BLoC. Eccezione tollerata: animazioni puramente locali con AnimationController.
5. **Mai funzioni che ritornano widget** (tipo \_buildHeader). Sempre classi widget di prima classe per non perdere i benefici del rebuild selettivo di Flutter.

### Architetturali
6. **Flusso a 6 layer**: UI → BLoC → UseCase → Repository → DataSource → DB. Sempre questo, anche per operazioni semplici.
7. **Ogni feature scrive solo sul proprio repository.** Eccezione: la dashboard può orchestrare delegando ai use case altrui.
8. **I BLoC non si parlano direttamente.** Mai. Comunicazione cross-feature solo via router (push/pop).
9. **Cross-feature import permessi**: solo domain/entities e domain/repositories. Mai data/, mai presentation/.
10. **DAG di dipendenze**: nessuna feature foglia importa dalla dashboard. Mai cicli.

### Dati
11. **Either<Failure, T>** ritornato da tutti i metodi dei repository. Mai eccezioni propagate verso BLoC.
12. **UUID v4 client-side** per tutte le PK. Mai auto-increment.
13. **Money in centesimi (intero)**, mai float/double per importi.
14. **Valori derivabili mai persistiti.** I KPI si calcolano runtime. L'ultimo lavoro per tipo si trova con ordinamento, non con flag.
15. **Eventi BLoC con dati minimi.** Mai trasportare lo stato corrente nell'evento — il BLoC ha già accesso al proprio state.
16. **copyWith** per modifiche puntuali dello stato. Mai ricostruire lo stato campo per campo.

### UI
17. **BlocBuilder solo dove la UI cambia.** Mai avvolgere intere pagine: lascia AppBar, FAB, nav bar fuori.
18. **Widget riutilizzabili in core/widgets/** se usati in 2+ schermate. Non duplicare mai un widget tra feature.
19. **context.read** nei callback (per mandare eventi). **context.watch** raramente nel build (preferire BlocBuilder).
20. **Tre widget BLoC ben distinti**: BlocBuilder per cambiare UI, BlocListener per effetti collaterali (toast, navigate), BlocConsumer quando servono entrambi.

### Use case
21. **Use case obbligatorio quando**: si tocca un repository, si applica logica di business non triviale, la logica è riutilizzabile.
22. **Use case non necessario quando**: l'azione è puro aggiornamento UI (indici, toggle, filtri). In quel caso il BLoC fa direttamente emit con copyWith.

### Sicurezza
23. **RLS attiva su ogni tabella** dal giorno 1. Nessuna tabella senza policy.
24. **Invarianti critiche replicate come CHECK constraint** Postgres oltre che nel dominio Dart.

---

## 11. Stato del progetto e prossimi passi

### Documenti già prodotti
- **ADR-001** — Schema database (decisioni di modellazione, tabelle, invarianti, RLS)
- **ADR-002** — Flussi architetturali (3 flussi sequenziali completi: registrazione veicolo, lettura dashboard, aggiunta lavoro)
- **Guida pratica GetIt & BLoC** — concetti, analogie, codice di esempio
- **Questo PROJECT_SPEC.md** — specifica complessiva

### Da definire prima dell'implementazione
- Eventi e stati BLoC concreti per ciascuna delle 6 feature (work in progress, viene fatto da te con review)
- Lista chiusa definitiva dei StandardServiceKind (~20 voci dal libretto meccanico)
- Lista chiusa definitiva dei ComponentKind (~20 voci)
- Catalogo dei widget riutilizzabili da estrarre in core/widgets/

### Ordine consigliato di implementazione
1. Setup progetto (struttura cartelle, pubspec, theme base, injection vuoto)
2. Schema Supabase applicato (migrazioni, RLS, indici)
3. Feature **auth** — la più indipendente
4. Feature **vehicle** — anagrafica + wizard, fondamento di tutto il resto
5. Feature **work_log** — storico e aggiunta lavoro
6. Feature **dashboard** — aggrega le precedenti
7. Feature **service_provider** e **profile** — secondarie
8. Router completo con shell route e guards
9. Testing dei BLoC più complessi

---

Fine specifica.

Questo documento è la fonte di verità del progetto. Le decisioni architetturali sono vincolanti: modifiche richiedono un nuovo ADR. Le convenzioni di codice non sono negoziabili — sono il risultato di scelte ragionate per garantire manutenibilità, testabilità e scalabilità.