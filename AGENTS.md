# AutoMob agent contract

These instructions are mandatory for every change under `auto_mob_v1/`.

## Before editing

1. Read `auto_mob_v1/AGENT.MD`.
2. Run `./tool/verify.ps1` from `auto_mob_v1/` to establish the baseline.
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
