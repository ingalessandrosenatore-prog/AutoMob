# Registrazione meccanico

## Flusso

La registrazione e un wizard unico con tre pagine non navigabili a swipe:

1. anagrafica del titolare;
2. dati dell'officina;
3. conferma dell'email.

La dipendenza completa e:

`RegistrationWizardPage -> AuthBloc -> use case -> AuthRepository -> datasource`

La pagina renderizza lo stato, invia eventi e mostra il dialogo. Validazione,
invio a Supabase e ripristino della fase pendente non sono nella UI.

## Persistenza e conferma

Quando Supabase richiede la conferma, il repository salva localmente soltanto
l'email pendente. Password e token non vengono salvati dall'app. La sessione
Supabase continua a essere gestita dal relativo SDK.

Al riavvio si controlla prima la sessione; se non esiste ma resta un'email
pendente, il router riapre `/auth/verify-email`. Il pulsante `Ho confermato`
controlla di nuovo la sessione e resta nel wizard con un avviso se manca.

Callback mobile da autorizzare nella redirect allow-list del progetto Supabase:

`com.infinty.automob.mechanic://login-callback/`

Lo stesso schema e registrato nell'Android Manifest e nell'iOS Info.plist.

## Comuni italiani

Il dropdown legge `assets/data/italian_municipalities.json`, generato dal file
ufficiale ISTAT "Elenco dei comuni italiani" aggiornato al 21 febbraio 2026.
Il file contiene 7.894 comuni con codice ISTAT, nome, sigla e nome provincia;
non richiede API a pagamento o connessione durante la compilazione del wizard.

Fonte: https://www.istat.it/classificazione/codici-dei-comuni-delle-province-e-delle-regioni/
