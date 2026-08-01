# Workshop feature

The workshop home owns the mechanic dashboard and vehicle workflow.

Production dependency path:

`UI -> BLoC -> UseCase -> Repository -> DataSource -> Supabase`

Nested navigation stays in the workshop shell branch:

`workshop -> vehicle configuration -> new work | work detail`

Mock data must be implemented by a mock datasource/repository so the UI and
BLoC do not change when Supabase is connected.
