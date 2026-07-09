# AutoMob — Istruzioni per Claude Code

## Prima di iniziare

**Leggi `ARCHITETTURA.md`** prima di toccare codice: contiene la mappa del
progetto (struttura cartelle, feature, RPC) in poche righe. Non serve leggere
l'intera codebase per orientarsi.

## Stack

Flutter · Clean Architecture (`domain/data/presentation` per feature) ·
BLoC/Cubit (`flutter_bloc`) · get_it (DI) · go_router (nav) ·
fpdart (`Either<Failure, T>`) · Supabase (backend) · equatable.

## Regole architetturali (vincolanti)

Le regole di layering (chi può importare cosa, niente funzioni che ritornano
`Widget`, BLoC UI-agnostic, ecc.) sono **applicate automaticamente** da
`tool/check_architecture.dart` — non serve ricordarle a memoria, lo script le
blocca. Il debito tecnico pre-esistente è tracciato in `tool/arch_baseline.txt`
e spiegato in `docs/TECH_DEBT.md`: non aggiungerne di nuovo.

Regole che lo script **non può verificare** (richiedono giudizio):

- **Dove mettere un widget estratto**: se è riutilizzabile tra feature diverse
  → `lib/core/widgets/`; se è specifico di una sola feature → dentro quella
  feature (`presentation/widgets/`). Non mettere mai in `core/` un widget che
  importa qualcosa da `features/` (è un segnale che non è davvero core — vedi
  `docs/TECH_DEBT.md` punto 1 per un caso reale di questo errore).
- **Niente `setState` che ribuilda un intero albero di widget.** Lo stato
  locale con `setState` è ammesso solo dentro widget piccoli e autonomi
  (es. un singolo bottone animato), mai nel widget "pagina" o in un ancestor
  che farebbe ricostruire tutto il sottoalbero sotto di lui. Se lo stato serve
  a più widget o incide su logica di business, usa BLoC/Cubit, non `setState`.
- **Cross-feature**: una feature può importare **solo il `domain`** di
  un'altra feature (entity, repository interface, usecase), mai il suo
  `data` o `presentation`.

## TDD — il test non è opzionale

Questo progetto si sviluppa in **TDD**: ogni nuovo usecase, repository
(impl) o bloc/cubit **deve avere un test corrispondente**, senza eccezioni.

Un'istruzione scritta non basta a farla rispettare — se scrivi la logica e
non il test, `flutter test` resta comunque verde (non c'è nessun test che
possa fallire). Per questo `tool/check_test_coverage.dart` lo verifica
**meccanicamente**: scandaglia `domain/usecases/`, `data/repositories/`,
`presentation/bloc/*_bloc.dart|*_cubit.dart` e pretende un file
`test/.../<stesso-nome>_test.dart` corrispondente. Se manca (ed è un file
nuovo, non in `tool/test_baseline.txt`), il gate blocca. Il codice
pre-esistente senza test è tracciato in baseline (debito, non nascosto):
quando scrivi il test per uno di quei file, cancella la sua riga dal
baseline — da quel momento tornerebbe a essere un errore se il test
sparisse di nuovo.

**Quindi**: quando aggiungi un usecase/repository/bloc, scrivi il test
*prima o insieme* al codice, non "dopo se c'è tempo". E deve essere verde,
non solo presente.

## Test e verifica — obbligatorio prima di finire

Prima di considerare un task concluso, esegui:

```
./tool/verify.ps1
```

Verifica architettura + copertura test (TDD) + `flutter analyze` +
`flutter test`. Se fallisce, **continua a correggere finché non è verde**
— non fermarti a metà. Un hook automatico (`.claude/settings.json`, `Stop`)
rilancia `verify.ps1` quando hai toccato `lib/` o `test/` e blocca la fine
del turno se fallisce: è un ulteriore livello di sicurezza, non un
sostituto — lancialo tu per primo appena hai finito di scrivere codice,
così vedi subito l'esito.

Quando scrivi test nuovi, replica lo stile dei test "golden" già presenti
in `test/features/vehicle/` (uno per usecase, uno per repository, uno per
bloc/cubit): stesso pattern di mocking con `mocktail`, stesso stile di
naming.

## Commit e push

Quando un task è completo e `tool/verify.ps1` è verde, esegui
`tool/ship.ps1 "messaggio"` (commit + push) **autonomamente**, senza
chiedere conferma — è pre-autorizzato per questo progetto. Scrivi messaggi
di commit brevi, in italiano o inglese coerentemente con lo stile esistente,
che spieghino il *perché* non il *cosa*.

## Skill disponibili

In `.claude/skills/` ci sono 19 skill ufficiali Flutter/Dart (test, coverage,
mock, layout responsivo, localizzazione, ffi, ecc.) — usale quando il task
corrisponde (es. `dart-generate-test-mocks` per generare mock,
`flutter-fix-layout-issues` per overflow/layout).

**Non esiste ed è stata volutamente esclusa** `flutter-apply-architecture-best-practices`:
prescrive MVVM + ChangeNotifier + Provider con struttura a cartelle per-tipo,
che è l'opposto dell'architettura reale di questo progetto (Clean Architecture
+ BLoC, per feature). Se mai dovesse ricomparire, **ignorala** — l'unica fonte
di verità architetturale è `ARCHITETTURA.md` + `tool/check_architecture.dart`.

## Documenti da mantenere aggiornati

Questi file sono la fonte di verità per orientarsi senza rileggere tutto il
codice. **Quando il codice cambia in modo che li renda inesatti, aggiornali
nella stessa sessione di lavoro** — non lasciarli decadere:

- `ARCHITETTURA.md` — mappa struttura progetto/feature
- `docs/DATABASE.md` — schema Supabase, RPC, RLS (fonte di verità: DB live —
  se cambia lo schema, rigenera con le query in fondo al file)
- `docs/TECH_DEBT.md` — debito tecnico tracciato
- `docs/ROADMAP.md` — stato di avanzamento feature per feature

`docs/AutoMob_DB_Reference.md` è **superato**, non consultarlo: usa
`docs/DATABASE.md`.
