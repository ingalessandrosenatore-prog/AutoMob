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

  ## Bug-fix verification

* For a reproducible bug, add or update a regression test that fails before the
  fix and passes after it whenever the behavior can be tested reliably at unit,
  BLoC, widget, integration, repository, or datasource level.
* Do not create meaningless tests only to satisfy structural coverage checks.
* If an automated regression test is not practical, explain why and provide a
  precise manual verification procedure for the affected behavior.
* Never claim that a bug is fixed only because analysis and existing tests pass.

## Completion contract

A task is not complete only because the code compiles or the verification
script passes.

Before declaring completion, report:

1. The identified root cause or, for a feature, the implemented behavior.
2. The complete functional flow affected:
   `UI -> BLoC -> UseCase -> Repository -> DataSource`.
3. Every modified file and the reason it was changed.
4. Tests added or updated, including the behavior each test proves.
5. Verification commands executed and their actual results.
6. The user-visible behavior that was verified.
7. Any behavior that could not be verified.
8. Remaining risks, assumptions, and edge cases.

Never claim that a bug is resolved without evidence.

If the change affects writes, deletion, authentication, authorization,
payments, user data, Supabase RLS, migrations, or cross-feature behavior,
explicitly mark it as high risk and provide the manual checks still required.
## Shared widget reuse policy

Before creating any new reusable widget, follow this order:

1. Search `common_ui_widget/` for an existing equivalent widget.
2. Reuse or extend the existing shared widget instead of creating a duplicate.
3. If no equivalent exists, inspect `auto_mob/lib/core/widgets/`.
4. If a reusable widget already exists in `auto_mob/lib/core/widgets/`:

   * move or extract it into `common_ui_widget/`;
   * preserve its existing public API whenever possible;
   * export it from the appropriate `common_ui_widget` barrel file;
   * update `auto_mob` imports to use `common_ui_widget`;
   * preserve a temporary compatibility export in `auto_mob` when removing it
     immediately would break existing imports;
   * verify all consuming applications after the extraction.
5. Use the newly shared widget from `common_ui_widget` in the active project.

Do not create a new app-local reusable widget when an equivalent widget already
exists in `common_ui_widget` or `auto_mob/lib/core/widgets/`.

New reusable widgets must be created directly inside `common_ui_widget`, not
inside an application, unless they are strictly application-specific and cannot
reasonably be reused.

Page-specific widget composition may remain inside the owning application when
it contains business-specific behavior, feature state, navigation, or domain
logic.

When extracting a widget from `auto_mob` to `common_ui_widget`:

* shared widgets must not import application features, BLoCs, repositories,
  use cases, datasources, service locators, or application routes;
* application-specific data must be provided through constructor parameters,
  callbacks, or presentation-only models;
* do not move business logic into `common_ui_widget`;
* update and verify every existing import before deleting the original file;
* run the verification scripts for `common_ui_widget`, `auto_mob`, and every
  other consuming application;
* report any API change, migrated import, compatibility export, and remaining
  migration work.

Do not declare the extraction complete until all consuming applications analyze
and test successfully.


