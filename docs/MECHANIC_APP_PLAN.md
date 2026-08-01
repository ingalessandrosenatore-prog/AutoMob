# AutoMob mechanic app plan

## Agreed scope

- Develop on `codex/mechanic-theme-foundation`; keep `main` demo-ready.
- Keep the owner and mechanic applications separate.
- Keep WorkLog app-specific for now.
- Share only the vehicle-registration widget that is proven identical.
- Extract any other widget only when the mechanic app needs it.
- Use separate app bootstraps and dependency injection for owner and mechanic.

## Incremental delivery

1. Extract `AmTheme` and `AmThemeColors` into `common_ui_widget`.
2. Apply the shared theme to owner and mechanic apps.
3. Build the first mechanic page against mock data and the supplied graphics.
4. Preserve the production dependency path even during the mock phase:
   `UI -> BLoC -> UseCase -> Repository -> DataSource`.
5. Replace the mock datasource with Supabase without rewriting the UI or BLoC.
6. Extract shared inputs, buttons or cards only when the second real consumer
   appears.

## Compatibility rule

When code moves from the owner app into `common_ui_widget`, keep the old owner
file as a compatibility export. Remove it only after a reference scan, green
verification of every consumer and explicit approval.

## Quality gates

The repository pre-push hook discovers every `*/tool/verify.ps1`. The owner
app, mechanic app and shared package must each pass their own verifier before a
push is accepted.

## Navigation map

Auth routes live outside the authenticated shell:

- `/splash`
- `/auth/login`
- `/auth/registration`
- `/auth/verify-email`

The authenticated area uses `StatefulShellRoute.indexedStack`:

- `/workshop` - Officina tab
  - `/workshop/vehicles/:vehicleId` - vehicle configuration
    - `works/new` - register work
    - `works/:workId` - work detail
- `/subscription` - Abbonamento tab

Both shell branches keep their widget tree and navigation stack alive when the
user changes tab. Feature widgets navigate through the typed methods in
`core/router/app_navigation.dart`, not through duplicated route strings.
