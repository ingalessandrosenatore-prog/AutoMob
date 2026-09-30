# Shared WorkLog package contract

This package implements the reusable WorkLog flow for AutoMob and the mechanic
backoffice.

Dependency path for every operation:

`UI -> BLoC -> UseCase -> Repository -> DataSource`

- The package owns the complete WorkLog vertical: domain, data, BLoCs,
  history, detail, wizard, the owner/mechanic history chrome and its internal
  navigation.
- It must never import `auto_mob` or `automob_backoffice_mech`, use GetIt, or
  own either application's router or shell.
- Apps open a single `WorkLogFeature`, inject the authenticated repository and
  provide a typed owner/mechanic launch. Only callbacks that leave WorkLog,
  such as mechanic notifications, remain app-owned.
- Supabase is allowed exclusively in this package's datasource; it uses the
  authenticated client injected by the app composition root.
- Keep migrations copy-first. Do not remove compatibility paths until both apps
  have migrated, reference scans are clean and deletion is explicitly approved.

Run `flutter analyze` and `flutter test` before completing a package change.
