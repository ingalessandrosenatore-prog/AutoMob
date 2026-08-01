# Subscription feature

Subscription and plan management remain separate from the workshop feature.

Production dependency path:

`UI -> BLoC -> UseCase -> Repository -> DataSource -> Supabase`

This feature owns subscription presentation and business rules; the router
only mounts its root page in the second persistent shell branch.
