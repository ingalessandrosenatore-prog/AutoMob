# Notifiche AutoMob - appunti per il corso

Data della sessione: 15 luglio 2026.

Questo file serve a riprendere la spiegazione senza perdere il contesto. Non
contiene token FCM, JWT, service role o chiavi private Firebase.

## Obiettivo concordato

Inviare notifiche push anche quando AutoMob e chiusa, usando:

- Supabase come fonte dei dati, motore delle regole, coda e scheduler;
- Firebase Cloud Messaging come servizio di consegna al telefono;
- Flutter per permesso, registrazione del dispositivo e gestione del tap.

Categorie iniziali:

1. `km`: nessun aggiornamento in `vehicle_history` da oltre due giorni;
2. `maintenance_kpi`: tagliando, distribuzione, cambio o inversione pneumatici
   negativi da oltre due giorni;
3. `revision`: sette giorni prima, un giorno prima e poi nei giorni dispari
   successivi alla scadenza.

Le notifiche KM e manutenzione si ripetono ogni due giorni finche l'utente non
aggiorna i dati. Qualsiasi nuovo record in `vehicle_history` vale come
aggiornamento KM.

## Stato raggiunto

- Firebase Android collegato al progetto `carHealth`.
- Il permesso Android viene richiesto correttamente.
- Un dispositivo reale e registrato in `public.device_tokens`.
- Gli invii reali delle tre categorie hanno risposto `sent`.
- Edge Functions `device-token` e `notification-dispatch` sono online.
- Tabelle outbox e delivery sono presenti con RLS e grant limitati.
- Gli otto job Cron estate/inverno sono attivi.
- L'Edge Function controlla `Europe/Rome`, evitando doppi invii al cambio ora.
- Il percorso errato `/dashboard` e stato sostituito con `/home`.
- La navigazione al tap aspetta autenticazione e router durante il cold start.
- Analisi Flutter senza errori.
- 15 test Flutter della feature e 3 test Deno superati.

Il tap sulla nuova build deve ancora essere provato su dispositivo. Le vecchie
notifiche conservano il vecchio payload e non sono una prova valida.

## Orari attivi

- 07:00: valutazione delle regole e creazione della coda;
- 09:00: KM se nello stesso giorno la revisione usa lo slot serale;
- 13:00: manutenzione/work log;
- 18:00: revisione oppure KM.

## Problemi incontrati e lezioni

### `denied` su Android non significa sempre rifiutato

Su Android 13+ Firebase Messaging puo restituire `denied` sia prima della prima
richiesta sia dopo un rifiuto. AutoMob usa quindi anche un flag locale in
SharedPreferences per distinguere i casi.

### Un Bloc singleton puo essere gia caricato

`BlocListener` ascolta le transizioni future, non lo stato che esisteva prima
del mount. `HomeView` controlla quindi anche un `DashboardLoaded` gia presente
nel primo frame.

### Token dispositivo e utente sono concetti diversi

Un utente Supabase non possiede automaticamente un token. Il token nasce su una
specifica installazione dopo consenso e viene collegato a `user_id`. Un utente
puo avere piu dispositivi; gli utenti vecchi devono aggiornare e aprire l'app.

### API key client e chiave server sono diverse

`firebase_options.dart` e `google-services.json` contengono configurazione
client distribuibile. `FIREBASE_SERVICE_ACCOUNT_JSON` contiene invece una
chiave privata server e vive soltanto nei secret Supabase. Una chiave privata
incollata in chat deve essere revocata e rigenerata.

## Percorso della spiegazione di domani

La lezione deve partire dalle basi e non dare per conosciuti Firebase,
JavaScript, SQL asincrono o notifiche Android.

### Modulo 1 - Modello mentale

- differenza tra database, scheduler e servizio push;
- perche il client non deve restare acceso;
- viaggio completo di una notifica con un esempio concreto.

### Modulo 2 - Token e permessi

- cos'e un token FCM;
- perche non identifica direttamente un utente;
- consenso Android 13+, rinnovo token, logout e multi-dispositivo;
- differenza tra API key pubblica e service account privato.

### Modulo 3 - Database e SQL

- lettura guidata delle tre nuove tabelle;
- RLS, grant e ruolo `service_role`;
- indici e ricerca dell'ultimo aggiornamento;
- CTE, lateral join, window function, `jsonb_agg` e deduplicazione;
- simulazione manuale di `notification_candidates(p_as_of)`.

### Modulo 4 - Edge Functions TypeScript

- `Deno.serve`, request e response;
- `async`, `await`, Promise, `fetch` e JSON;
- client utente contro client amministrativo;
- azioni `preview`, `enqueue_test`, `send_test`, `evaluate`, `dispatch`;
- retry FCM, token non valido e revalidazione prima dell'invio.

### Modulo 5 - Flutter e Clean Architecture

- entity, repository, data source e use case;
- bootstrap Firebase;
- dialogo educativo e popup Android;
- registrazione del token nella Edge Function;
- foreground, background, app chiusa e tap;
- perche il logout non viene bloccato da Firebase.

### Modulo 6 - Cron e fusi orari

- perche Postgres Cron usa UTC;
- coppie estate/inverno;
- secondo controllo in `Europe/Rome`;
- ordine 07:00, 09:00, 13:00 e 18:00;
- come fermare e riattivare i job.

### Modulo 7 - Test e laboratorio

- leggere i test Dart e Deno;
- usare una data simulata senza aspettare domani;
- seguire una riga da candidate a outbox e delivery;
- provocare in sicurezza `no_device`, `cancelled`, `failed` e `sent`;
- aggiungere insieme una quarta categoria di esempio.

## File da leggere durante la lezione

- `docs/NOTIFICATIONS.md`: manuale operativo completo;
- `supabase/migrations/20260715192315_notification_system.sql`: schema e regole;
- `supabase/functions/notification-dispatch/index.ts`: orchestrazione e invio;
- `supabase/functions/notification-dispatch/logic.ts`: orario e testi;
- `supabase/functions/device-token/index.ts`: registrazione dispositivo;
- `lib/features/notifications/`: feature Flutter completa;
- `lib/core/router/app_router.dart`: comportamento al tap;
- `test/features/notifications/`: test Dart;
- `supabase/functions/tests/`: test Deno.

## Prima operazione della prossima sessione

Installare la build aggiornata:

```powershell
flutter run --profile --dart-define-from-file=.env
```

Poi inviare una nuova notifica di test e verificare che il tap apra `/home` o
`/lavori` senza mostrare `Error not found`.
