# AutoMob mechanic app contract

The mechanic app follows feature-based Clean Architecture with BLoC:

`UI -> BLoC -> UseCase -> Repository -> DataSource`

## Rules

- UI renders state, dispatches BLoC actions, navigates and shows UI effects.
- BLoCs depend on use cases, never repositories or datasources.
- Infrastructure SDK types remain in the data layer.
- Supabase calls are allowed only in datasources.
- Mock data must enter through a mock datasource/repository, never be embedded
  in a page that will later load real data.
- Router, dependency injection, shell and app bootstrap remain app-specific.
- The shared `packages/automob_work_log` package owns WorkLog domain, data,
  BLoCs and reusable page bodies. This app provides its DI registrations, route
  wrappers, navigation and mechanic-specific app bar only.
- The shared WorkLog package never imports this app and never uses GetIt. Pass
  the selected vehicle through `WorkLogLaunchContext`.
- Import shared presentation code only from `common_ui_widget`.
- Do not add `setState`; use BLoC/Cubit unless a line-level architecture ignore
  documents a purely local animation exception.

Run `./tool/verify.ps1` before completing any mechanic-app change.
