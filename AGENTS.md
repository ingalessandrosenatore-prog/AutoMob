# AutoMob agent contract

These instructions are mandatory for every change in this monorepo.

## Before editing

1. Read the `AGENT.MD` in the project being changed.
2. Run that project's `./tool/verify.ps1` to establish the baseline.
3. Inspect `git status` and preserve unrelated user changes.
4. For a new workflow, write the dependency path before coding:
   `UI -> BLoC -> UseCase -> Repository -> DataSource`.

If the proposed path skips a layer, stop and redesign it before editing.

## Architecture rules

- Pages and widgets may dispatch BLoC/Cubit actions, render state, navigate, and
  show UI effects. They must not call use cases, repositories, datasources,
  Supabase, Firebase, SharedPreferences, or service locators.
- BLoCs and Cubits depend on use cases, never repositories or datasources.
- `GetIt` is restricted to `main.dart`, `core/di/`, and `core/router/`.
- Infrastructure SDK types must stay in the data layer.
- Cross-feature imports may target only the other feature's `domain/`.
- New `setState` calls are forbidden unless a line-level
  `arch-ignore(R18): <reason>` documents a purely local animation exception.
- Do not add architecture debt to a baseline to make a new change pass.
  Baselines are only for debt that predates the active task.

## Verification and commits

- Run `./tool/verify.ps1` after implementation.
- A green `flutter analyze` alone is not sufficient.
- Do not use raw `git commit` for project changes. When the user explicitly
  requests a commit, use `./tool/ship.ps1 "<message>"`.
- Never bypass hooks with `--no-verify`.
- Do not commit `.env`, service-account files, signing keys, or
  `supabase/.temp/`.

## Monorepo boundaries

- `auto_mob/` is the owner app.
- `automob_backoffice_mech/` is the mechanic app.
- `common_ui_widget/` contains only presentation code shared by both apps.
- `packages/automob_work_log/` owns the shared WorkLog feature: its domain,
  data layer, BLoCs and reusable page bodies/wizard. It may use the authenticated
  Supabase client only inside its data layer.
- Each app owns its composition root (DI), outer routes and app shell. The
  shared package owns the complete WorkLog flow, including its owner/mechanic
  history app bars and internal history/detail/wizard navigation.
- The package receives a typed owner/mechanic launch and an authenticated
  repository. It never imports either app or uses GetIt. Callbacks remain only
  for destinations outside WorkLog, such as mechanic notifications.
- Migrate copy-first: retain owner compatibility sources/exports until both apps
  use the package, reference scans are clean, and deletion has been explicitly
  approved.

## Quality Rules
- Do not implement an entire feature or a broad change in one monolithic file.
  Split code by responsibility and layer: pages/widgets, state management,
  use cases, repositories, data sources, models and reusable helpers belong in
  separate focused files. Keep each file as small and cohesive as practical;
  when a file starts accumulating unrelated responsibilities, extract them
  before continuing.
- Before adding substantial code, identify the file boundaries and place each
  class, widget or helper in the narrowest appropriate file. Reuse existing
  components and create a new focused file when that improves readability,
  testability or reuse; do not hide unrelated classes at the bottom of a page
  or feature file merely to reduce the file count.
- Keep the implementation small, sharp, easy to understand. Try to write elegant code in a state of grace. Don't settle for the first - - thing that comes to mind, try to find the most minimal and better working design. Don't introduce slop: very fragile code that just - - patches specific cases, dead code, useless code and code ways more complicated of how it should be.
- Comment important inference code where the model mechanics, cache lifetime, memory policy, or API orchestration are not obvious from - the local code.
- Prefer comments beside the implementation over separate design documents.
- Keep comments instructive and compact: explain why a shape, ordering, cache boundary, or memory choice exists.
