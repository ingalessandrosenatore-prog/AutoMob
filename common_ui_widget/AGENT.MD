# Shared presentation package contract

`common_ui_widget` owns visual code that is used by more than one AutoMob app.

## Allowed

- Theme data, theme extensions, colors, typography and visual tokens.
- Reusable widgets with input data and callbacks.
- Widget and golden tests that do not depend on an app.

## Forbidden

- BLoCs, use cases, repositories and datasources.
- Supabase, Firebase, SharedPreferences, GetIt and app routers.
- Imports from `auto_mob/` or `automob_backoffice_mech/`.
- Moving a widget here before a second app needs it.

Run `./tool/verify.ps1` before completing any package change.
