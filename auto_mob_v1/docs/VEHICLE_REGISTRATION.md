# Registrazione veicolo

Stato al 15 luglio 2026: lookup InfoTarga attivo tramite Edge
Function versione 2. L'inserimento manuale resta sempre disponibile come
fallback dopo la chiusura di un errore.
Il secret server-side `INFOTARGA_API_KEY` e' configurato nel progetto Supabase.

## Flusso Clean Architecture

```text
UI wizard -> VehicleRegistrationBloc -> use case -> repository -> data source
          -> SharedPreferences / Supabase Edge Function / RPC PostgreSQL
```

Gli step sono: meccanico, targa, verifica, lavori iniziali, foto. "Non ho un
meccanico" è attivo e avanza senza creare associazioni.

Lo step Targa valida `AA123AA` prima della chiamata. I controller di Targa,
Verifica, Lavori e Foto vengono risincronizzati dalla bozza quando l'utente
torna indietro. Una bozza manuale riaperta riparte da Verifica senza effettuare
una nuova richiesta esterna.

## Chiave InfoTarga ed Edge Function

Flutter chiama soltanto `supabase.functions.invoke('vehicle-lookup')`. Il
sorgente server è in `supabase/functions/vehicle-lookup/index.ts` e non viene
incluso nella build Flutter. `INFOTARGA_API_KEY` deve essere un secret Supabase,
mai una variabile del client.

La funzione verifica il JWT, valida `^[A-Z]{2}[0-9]{3}[A-Z]{2}$`, interroga
InfoTarga con timeout di 12 secondi, conserva il risultato per 7 giorni e
restituisce campi normalizzati, warning e `lookupId`.

## Tabelle coinvolte

| Tabella | Scrittura | Scopo |
|---|---|---|
| `mechanics` | nessuna nel wizard | verifica codice e stato attivo |
| `vehicle_lookup_results` | Edge Function | risposta temporanea, owner e scadenza |
| `vehicles` | RPC finale | anagrafica del veicolo |
| `maintenance_records` | RPC finale | sessione iniziale opzionale |
| `maintenance_items` | RPC finale | lavori iniziali |
| `vehicle_mechanics` | RPC finale | associazione opzionale officina-veicolo |
| `vehicle_external_snapshots` | RPC finale | copia permanente della risposta esterna |

Lo snapshot conserva payload originale e campi estratti di assicurazione,
emissioni, idoneità neopatentati, revisione e furto.

## RLS della migration

- `vehicle_lookup_results`: l'utente legge solo `owner_id = auth.uid()`; scrive
  esclusivamente la Edge Function con service role.
- `vehicle_external_snapshots`: select/insert solo per il proprietario del
  veicolo.
- `mechanics`: un autenticato legge officine attive o la propria riga; può
  aggiornare solo la propria riga. Nessun accesso anonimo.
- `vehicles` e `vehicle_mechanics`: restano le policy owner esistenti; l'RPC
  ricontrolla inoltre attività, id e codice del meccanico.

La revisione completa delle RLS per interventi del meccanico, abbonamenti e
back office è fuori da questa modifica e resta da progettare separatamente.

La RPC legge `vehicle_lookup_results` con una normale `SELECT`. Non usa
`SELECT ... FOR UPDATE`, perche' il lookup e' immutabile dal client e quel lock
richiederebbe inutilmente il privilegio `UPDATE`. In questo modo la
registrazione conserva il principio del minimo privilegio senza usare
`SECURITY DEFINER` e senza ampliare le policy.

## Bozza e tentativo singolo

SharedPreferences conserva i cinque step, meccanico, `lookupId`,
`lookupAttemptConsumed`, modalità edit/view e percorso foto. Una bozza con
tentativo consumato riparte dal terzo step e non richiama InfoTarga. Modificare
la targa cancella `lookupId`, non il flag consumato.

Rete e timeout non consumano il tentativo. Una risposta effettiva del provider,
anche terminale, lo consuma. Chiudi porta alla compilazione manuale; solo rete e
timeout offrono anche Riprova. La chiusura del popup azzera lo stato UI della
failure: il passaggio da Verifica a Lavori non puo' mostrare nuovamente lo stesso
errore. Anche il warning di risposta parziale viene azzerato dopo "Visualizza
dati".

## Failure e targhe di test

Failure distinte: `InvalidPlate`, `Network`, `Timeout`, `BadRequest`,
`Unauthorized`, `Forbidden`, `RateLimited`, `Server`, `NoData`,
`MalformedResponse`. Gli errori dei singoli blocchi esterni sono warning in un
`Right`, non `Left` dell'intera richiesta.

Una configurazione server incompleta (per esempio il secret InfoTarga mancante)
restituisce `configuration-error` ed e' mappata su `Server`, non su
`Unauthorized`: in questo modo non viene confusa con un JWT utente non valido.

| Targa | Risultato atteso |
|---|---|
| `AA000AA` | Right parziale, edit |
| `BB000BB` | Right completo, view |
| `CC000CC`, `DD000DD` | Right parziale |
| `FF000FF` | Right, furto presente |
| `GG000GG` | Right, storico revisione |
| `HH000HH` | Right, assicurazione particolare |
| `JJ000JJ` | Right con warning assicurazione |
| `KK000KK` | Right con warning emissioni |
| `LL000LL` | Right con warning idoneità |
| `MM000MM` | Right con warning revisione |
| `NN000NN` | Right con warning furto |
| `ER400ER` | Left BadRequest, solo Chiudi |
| `ER401ER` | Left Unauthorized, solo Chiudi |
| `ER403ER` | Left Forbidden, solo Chiudi |
| `ER429ER` | Left RateLimited, solo Chiudi |
| `ER500ER` | Left Server, solo Chiudi |

## Salvataggio finale

`crea_veicolo_con_storico` riceve `veicolo`, `lavori`, `mechanic_id`,
`mechanic_code` e `lookup_id`. In una transazione crea tutte le righe, verifica
owner/scadenza/targa del lookup e copia lo snapshot. Ogni errore fa rollback.
Se la copia locale della foto fallisce dopo il commit, l'app mostra un warning
e non rilancia l'RPC.

La chiusura del wizard usa il popup di stato comune con icona di allerta e due
scelte esplicite: `Salva draft e chiudi` conserva la bozza locale, mentre
`Scarta e chiudi` la elimina prima di uscire.

La foto viene copiata nella cartella persistente dell'app dopo il commit della
RPC. La chiave locale normalizza sempre la targa in maiuscolo: la stessa foto
viene quindi ritrovata anche quando Supabase restituisce `vehicles.plate` in
minuscolo. Restano leggibili anche chiavi e file creati dallo schema locale
precedente.

`supabase/seed.sql` inserisce l'officina Giordano solo dopo la creazione del suo
utente Auth. Un UUID tutto zero non è valido a causa della foreign key verso
`auth.users`.

## Compatibilita' carburanti

Il data source normalizza le etichette UI nei valori canonici del database:
varianti ibride -> `ibrido`, combinazioni GPL -> `gpl`, combinazioni metano ->
`metano`. Il vincolo `vehicles.fuel_valid` include anche `idrogeno`.
