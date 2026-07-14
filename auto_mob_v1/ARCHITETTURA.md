# AutoMob — Mappa dell'architettura

> Leggi questo file **prima** di modificare codice. Ti basta questo per orientarti:
> non serve leggere l'intera codebase. Se qualcosa qui non corrisponde più al
> codice reale, **aggiorna questo file** nella stessa modifica.

## Stack

Flutter · **Clean Architecture** (`domain / data / presentation` per feature) ·
**BLoC/Cubit** (`flutter_bloc`) · **get_it** (DI) · **go_router** (nav) ·
**fpdart** (`Either<Failure, T>`, niente eccezioni che risalgono la UI) ·
**Supabase** (backend, vedi `docs/DATABASE.md`) · **equatable**.

Regole di layering complete (chi può importare cosa) e i controlli automatici:
`docs/TECH_DEBT.md` + `tool/check_architecture.dart`.

## Struttura

```
lib/
├── core/                    trasversale, NON conosce le feature (eccetto di/ e router/)
│   ├── di/                  injection_container.dart — composition root, monta tutto
│   ├── router/              go_router (StatefulShellRoute.indexedStack: le 3 tab restano vive) + shell scaffold (bottom bar) + AmFadeThroughPage (transizione pagine pushate)
│   ├── error/               Failure (sealed class) + Exception per il layer data
│   ├── widgets/              widget DAVVERO riutilizzabili tra feature (buttons/ card/ input/ dialog/ smart/ blur/ effects/)
│   ├── ios_animation_gbt/    liquid zoom transition riutilizzabile per pagine, modali e popup
│   ├── ios_animation_claude/ liquid zoom transition (variante Claude): LiquidZoom, morph a molla trigger→pagina/modale/popup con luce, blur e riatterraggio
│   ├── config/               feature flags (es. performance_flags.dart)
│   ├── constants/             cataloghi statici (es. parts_catalog.dart)
│   ├── theme/, types/        tema app, enum condivisi
│
└── features/
    ├── auth/                 login (email/Google/Apple), signup, sessione. BLoC: AuthBloc
    ├── dashboard/             home, KPI veicolo, card riepilogo. BLoC: DashboardBloc
    ├── vehicle/               wizard aggiunta veicolo, lista veicoli, aggiorna km, KPI manutenzione.
    │                          BLoC: AddVehicleBloc · Cubit: KmUpdateCubit
    ├── work_log/              registrazione interventi di manutenzione + storico lavori.
    │                          BLoC: WorkLogBloc, WorkLogHistoryBloc
    ├── servizi/               stub: solo una pagina UI, nessun domain/data ancora
    ├── profile/               placeholder, vuota
    └── service_provider/      placeholder, vuota
```

Ogni feature (quando completa) segue:
```
features/<nome>/
├── domain/          entities, repositories (interfacce), usecases — Dart puro, zero Flutter
├── data/             models, datasources, repositories (implementazione) — parla con Supabase
└── presentation/     bloc/cubit, pages, widgets — UI + state management
```

## Le 3 RPC che scrivono sul DB (mai INSERT/UPDATE diretti per queste)

`crea_veicolo_con_storico` · `crea_sessione_manutenzione` · `aggiorna_km_veicolo`
— dettagli e schema completo in **`docs/DATABASE.md`**.

## Harness (verifica automatica)

- `tool/check_architecture.dart` — controlla le regole di layering (vedi sopra)
- `tool/check_test_coverage.dart` — TDD: ogni usecase/repository/bloc deve avere un test corrispondente
- `tool/verify.ps1` — architettura + copertura test + `flutter analyze` + `flutter test`, deve essere verde prima di ogni commit
- `tool/ship.ps1 "messaggio"` — commit + push, ma solo se `verify.ps1` passa
- `tool/arch_baseline.txt` + `tool/test_baseline.txt` + `docs/TECH_DEBT.md` — debito tecnico tracciato (violazioni note, non nascoste)

## Documenti collegati

- `docs/DATABASE.md` — schema Supabase, RPC, RLS (fonte di verità: DB live, non questo file)
- `docs/TECH_DEBT.md` — debito tecnico tracciato (architettura + analyze)
- `docs/ROADMAP.md` — stato di avanzamento feature per feature
- `docs/PRODUCTION_READINESS_PLAN.md` — piano verso la produzione
