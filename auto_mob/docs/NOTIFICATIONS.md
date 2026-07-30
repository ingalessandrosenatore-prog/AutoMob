# Notifiche push AutoMob

Questa guida descrive sia il funzionamento sia il motivo delle scelte fatte.
La feature e attiva. Firebase Android, il token reale e il service account FCM
sono stati verificati con invii reali; gli otto job Cron sono abilitati.

## 1. Architettura in breve

```text
Flutter -> Firebase richiede il permesso e genera il token del dispositivo
Flutter -> Edge Function device-token salva il token in Supabase
Cron -> Edge Function notification-dispatch valuta le regole
Postgres -> notification_outbox impedisce duplicati e conserva lo stato
Edge Function -> Firebase Cloud Messaging -> telefono Android/iOS
```

Il client non deve restare aperto. Firebase mantiene il collegamento con il
dispositivo e mostra la notifica anche quando AutoMob non e in esecuzione.
Supabase conserva dati, regole, coda e storico; Firebase fa soltanto la consegna.

Un token FCM identifica una singola installazione dell'app, non la persona.
Lo stesso utente puo quindi avere piu token attivi, per esempio telefono e
tablet. Un logout disattiva il token di quell'installazione.

## 2. Le tre categorie

| Categoria | Regola | Ripetizione | Orario italiano |
|---|---|---|---|
| `km` | nessuna riga nuova in `vehicle_history` da piu di 2 giorni | ogni 2 giorni finche arriva un aggiornamento | 18:00, oppure 09:00 se nello stesso giorno c'e la revisione |
| `maintenance_kpi` | almeno un KPI tra tagliando, distribuzione, cambio/inversione pneumatici e negativo da piu di 2 giorni | ogni 2 giorni finche il KPI resta negativo | 13:00 |
| `revision` | 7 giorni prima, 1 giorno prima, poi 1, 3, 5... giorni dopo | alle scadenze indicate | 18:00 |

Per la manutenzione viene creata una sola notifica per veicolo. Il campo JSON
`reasons` puo contenere piu elementi, ma l'utente non riceve quattro push.
Qualsiasi nuovo record in `vehicle_history` e considerato un aggiornamento KM.

Gli orari sono calcolati in `Europe/Rome`. In Postgres sono salvati in UTC;
l'Edge Function controlla di nuovo l'ora italiana, quindi il doppio job
estate/inverno non produce un doppio invio durante il cambio dell'ora.

## 3. Tabelle e funzione SQL

La migration `20260715192315_notification_system.sql` crea:

- `device_tokens`: token FCM, piattaforma e stato attivo;
- `notification_outbox`: una coda durevole con testo, categoria, data prevista,
  stato e `deduplication_key` univoca;
- `notification_deliveries`: risultato dell'invio per ogni dispositivo;
- `notification_candidates(p_as_of)`: funzione che restituisce soltanto i
  veicoli che in quella data rispettano una regola.

La scansione non legge prima tutti gli utenti. Parte da `vehicles` e usa query
SQL indicizzate per trovare l'ultimo aggiornamento e l'ultimo elemento di ogni
tipo. Questo lascia a Postgres filtro, join e aggregazione, evitando di
trasferire l'intero database a JavaScript.

Parole SQL usate nella migration:

- `with ... as`: assegna un nome a un risultato intermedio; rende leggibili le
  regole una alla volta;
- `left join lateral`: per ogni veicolo esegue la piccola ricerca dell'ultima
  riga collegata; con l'indice `(vehicle_id, created_at desc)` e efficiente;
- `row_number() over (partition by ...)`: ordina gli elementi dentro ogni
  coppia veicolo/tipo e consente di prendere il piu recente;
- `jsonb_agg`: raccoglie i KPI negativi in `reasons` senza creare piu push;
- `union all`: unisce le tre categorie senza nascondere righe valide;
- `security definer`: esegue la funzione con i privilegi del proprietario;
  subito dopo viene fissato il `search_path` per evitare oggetti malevoli;
- `revoke` e `grant`: negano l'accesso ai client e lo concedono soltanto a
  `service_role`; RLS resta una seconda barriera;
- `on conflict`/errore `23505`: la chiave di deduplicazione rende innocuo un
  secondo tentativo dello stesso job.

`p_as_of` e una data passata come parametro. In produzione e oggi; nei test puo
essere una data simulata, quindi non serve aspettare il giorno successivo.

## 4. Edge Functions, spiegate

### `device-token`

Richiede un JWT Supabase valido. `auth.getUser()` verifica sul server chi ha
fatto la richiesta. L'azione `register` usa `upsert`: inserisce il token se non
esiste, altrimenti aggiorna proprietario, piattaforma e data. `unregister`
imposta `is_active = false`; non cancella lo storico.

### `notification-dispatch`

Le azioni automatiche accettano soltanto il secret conservato in Vault. Le
azioni di test accettano un normale utente autenticato e filtrano sempre per il
suo `user_id`. Anche `send_test` ricontrolla che `vehicle_id` appartenga a lui.

Metodi JavaScript principali:

- `await`: attende una Promise prima di continuare;
- `createClient(url, key)`: crea il client Supabase della funzione;
- `.rpc(nome, parametri)`: chiama una funzione Postgres;
- `.from(nome)`: seleziona una tabella;
- `.select()`, `.insert()`, `.update()`, `.upsert()`: leggono o modificano righe;
- `.eq(campo, valore)`: aggiunge un filtro di uguaglianza;
- `fetch(url, options)`: esegue la richiesta HTTP verso FCM;
- `for (const item of items)`: ciclo intenzionalmente semplice usato per coda,
  dispositivi e tre tentativi di rete;
- `Deno.env.get`: legge un secret della Edge Function senza inserirlo nel git;
- `JSON.parse`/`JSON.stringify`: convertono tra testo JSON e oggetti;
- `try/catch`: intercetta errori di rete o configurazione e salva un esito utile.

Prima di spedire una riga reale, la funzione rivaluta i candidati. Se nel
frattempo l'utente ha aggiornato l'auto, la riga viene marcata `cancelled`.
Un token rifiutato definitivamente da FCM viene disattivato automaticamente.

## 5. Flutter e permessi

La feature segue i livelli gia usati dal progetto:

```text
presentation -> use case -> repository -> data source Firebase/Supabase/local
```

`FirebaseBootstrap.initialize()` prova a inizializzare Firebase. Se i file di
configurazione non sono ancora presenti, AutoMob continua ad avviarsi e la
richiesta notifiche non viene mostrata.

Quando esiste un veicolo reale, `HomeView` mostra prima un dialogo AutoMob:

- `Non ora`: salva in `SharedPreferences` un rinvio di 7 giorni;
- `Attiva`: chiama `FirebaseMessaging.requestPermission()` e, se autorizzato,
  registra il token tramite `device-token`.

Su Android 13+ il popup e gestito dal sistema grazie a `POST_NOTIFICATIONS` nel
manifest. Su Android precedenti il permesso e normalmente gia concesso. Su iOS
la stessa chiamata Dart richiede alert, badge e suono, ma la consegna funzionera
solo dopo aver configurato APNs nell'account Apple/Firebase.

`NotificationMessageCoordinator` gestisce quattro casi:

1. token gia autorizzato all'avvio: lo registra;
2. token rinnovato da Firebase: registra quello nuovo;
3. notifica ricevuta con app aperta: mostra uno SnackBar;
4. tap su notifica chiusa/background: apre la dashboard del veicolo indicato.

Il logout tenta di disattivare il token ma non viene mai bloccato da un errore
Firebase o di rete.

## 6. Configurazione Firebase da completare

1. Creare/selezionare il progetto Firebase e aggiungere l'app Android con il
   package presente in `android/app/build.gradle`.
2. Eseguire dalla cartella Flutter:

   ```powershell
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```

   Il comando genera la configurazione client e collega Android. Non committare
   credenziali server; i file client Firebase non contengono la chiave privata.
3. In Firebase Console creare un service account per Firebase Cloud Messaging
   HTTP v1 e scaricare il JSON.
4. In Supabase Dashboard, Edge Functions, Secrets, creare
   `FIREBASE_SERVICE_ACCOUNT_JSON` incollando l'intero JSON su una riga valida.
5. Fare prima `preview`, poi `send_test` su un telefono reale.
6. Solo dopo il test, attivare i Cron con la query della sezione 8.

Per iOS, in futuro: aggiungere l'app iOS in Firebase, caricare la chiave APNs,
abilitare Push Notifications e Background Modes in Xcode, quindi provare su un
dispositivo fisico. Il codice Dart e `remote-notification` sono gia predisposti.

## 7. Test manuali immediati

Non serve un bottone nel pannello Supabase e non serve aspettare Cron. Recupera
il JWT dell'utente autenticato (il `access_token` della sessione Supabase) e la
publishable/anon key, quindi usa PowerShell:

```powershell
$url = 'https://tvxcyjqaiyxmmhktwhdb.supabase.co/functions/v1/notification-dispatch'
$headers = @{
  Authorization = "Bearer $accessToken"
  apikey = $anonKey
  'Content-Type' = 'application/json'
}
```

Anteprima senza scrivere niente:

```powershell
$body = @{ action = 'preview'; as_of = '2026-07-15' } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body
```

Anteprima di un solo veicolo: aggiungere `vehicle_id = 'UUID'` al body.

Inserimento di righe di test nell'outbox, senza inviarle:

```powershell
$body = @{ action = 'enqueue_test'; as_of = '2026-07-15' } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body
```

Invio immediato di una categoria, ignorando le regole temporali:

```powershell
$body = @{
  action = 'send_test'
  vehicle_id = 'UUID-DEL-PROPRIO-VEICOLO'
  category = 'km' # oppure maintenance_kpi / revision
} | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri $url -Headers $headers -Body $body
```

`send_test` richiede che il telefono abbia gia accettato il permesso, registrato
il token e che il secret Firebase sia configurato.

Query utili nel SQL Editor:

```sql
-- La regola pura, senza invio e con data simulata.
select *
from public.notification_candidates('2026-07-15')
order by category, vehicle_id;

-- Ultime righe della coda.
select category, status, is_test, scheduled_for, last_error
from public.notification_outbox
order by created_at desc
limit 30;

-- Risultato per dispositivo (il token non viene mostrato).
select status, error_code, attempted_at
from public.notification_deliveries
order by attempted_at desc
limit 30;
```

## 8. Attivare o fermare Cron

I job sono attualmente `active = true`. Per riattivarli dopo una sospensione:

```sql
do $$
declare notification_job record;
begin
  for notification_job in
    select jobid from cron.job
    where jobname like 'automob-notifications-%'
  loop
    perform cron.alter_job(
      job_id := notification_job.jobid,
      active := true
    );
  end loop;
end;
$$;
```

Per fermarli, eseguire la stessa query sostituendo `true` con `false`.
Controllo stato:

```sql
select jobid, jobname, schedule, active
from cron.job
where jobname like 'automob-notifications-%'
order by jobname;
```

## 9. Test automatici

```powershell
flutter analyze
flutter test
npx --yes deno test supabase/functions/tests/notification-dispatch-test.ts
```

I test Dart verificano use case, repository e dialogo del permesso. Il test
Deno verifica testi, fuso Europe/Rome e protezione dal doppio job ora legale.

## 10. Aggiungere una categoria in futuro

1. aggiungere il valore al check di `notification_outbox` con una migration;
2. produrre la nuova riga in `notification_candidates`;
3. aggiungere testo e slot in `logic.ts`/`index.ts`;
4. aggiungere i test Deno e Dart necessari;
5. creare o modificare il job Cron soltanto se serve un nuovo orario.

La parte token e la consegna multi-dispositivo non cambia.
