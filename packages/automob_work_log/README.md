# AutoMob WorkLog

Feature condivisa da `auto_mob` e `automob_backoffice_mech`.

Il package possiede il flusso `UI -> BLoC/Cubit -> UseCase -> Repository -> DataSource` per:

- elenco e selezione dei veicoli;
- storico paginato e refresh;
- dettaglio del lavoro e dei ricambi;
- wizard `Dati -> Ricambi -> Costi`;
- salvataggio atomico tramite RPC Supabase.

Le app aprono un unico `WorkLogFeature`, iniettano il repository autenticato e
specificano un lancio tipizzato:

- `OwnerWorkLogLaunch`: il package carica i veicoli e mostra internamente
  selettore e pulsante `+`;
- `MechanicWorkLogLaunch`: l'app passa il veicolo selezionato e il package
  mostra internamente back, notifiche e FAB `Aggiungi lavoro`.

Storico, dettaglio, wizard, BLoC/Cubit, use case e navigazione interna restano
quindi identici nelle due app. Le callback esterne servono solo per uscire dalla
feature o aprire destinazioni esterne, come le notifiche.

Il package non usa GetIt e non importa nessuna delle due applicazioni.
