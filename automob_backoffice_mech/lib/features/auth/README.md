# Auth feature

Future code follows `presentation -> domain -> data`.

- `presentation/`: Auth BLoC and login, registration, verification pages.
- `domain/`: session entities, repository contract and auth use cases.
- `data/`: Supabase datasource, models and repository implementation.

The router observes Auth state through `AppRouterDependencies`; Auth must not
import or call `GoRouter` directly.
