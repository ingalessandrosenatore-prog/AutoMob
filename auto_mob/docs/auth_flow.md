# Auth Feature — Mappa completa stati, eventi, widget e query

---

## EVENTI

| Evento | Chi lo lancia | Quando |
|---|---|---|
| `CheckSessionEvent` | `SplashScreen.initState` (postFrameCallback) | App aperta, primo frame renderizzato |
| `LoginWithEmailEvent(email, password)` | `LoginView` — tasto Login | Utente preme Login |
| `LoginWithGoogleEvent` | `LoginView` — tasto Google | Utente preme Google |
| `LoginWithAppleEvent` | `LoginView` — tasto Apple | Utente preme Apple |
| `SignupWithEmailEvent(name, email, password)` | `RegistrationView` — tasto Registrati | Utente preme Registrati |
| `LogoutEvent` | da implementare in HomeView | Utente preme Logout |
| `GoToLoginEvent` | **orphan** — non usato, nav gestita da GoRouter | — |
| `GoToRegistrationEvent` | **orphan** — non usato, nav gestita da GoRouter | — |

---

## STATI

| Stato | Significa | Dati contenuti |
|---|---|---|
| `AuthInitial` | BLoC appena creato, nessuna operazione iniziata | nessuno |
| `AuthLoading` | Operazione async in corso | nessuno |
| `AuthAuthenticated` | Sessione valida o login/signup riuscito | `AppAuthUser user` (id, email) |
| `AuthUnauthenticated` | Nessuna sessione attiva | nessuno |
| `AuthError` | Operazione fallita | `String message` |
| `AuthLoggedOut` | Logout completato con successo | nessuno |
| `AuthShowLogin` | **orphan** — non usato | nessuno |
| `AuthShowRegistration` | **orphan** — non usato | nessuno |

---

## FLUSSO EVENTO → USE CASE → QUERY → STATO

### `CheckSessionEvent`
```
SplashScreen.initState
    └─► AuthBloc._onCheckSession
            emit(AuthLoading)
            └─► CheckSession (use case)
                    └─► AuthRepositoryImpl.checkSession()
                            └─► AuthRemoteDataSourceImpl.checkSession()
                                    └─► supabaseClient.auth.currentSession  ← QUERY (sincrona, in memoria)
                                            │
                                            ├─ session != null  →  Right(AppAuthUserModel)
                                            │       emit(AuthAuthenticated)
                                            │
                                            └─ session == null  →  Right(null)
                                                    emit(AuthUnauthenticated)
                        in caso di eccezione
                            └─► Left(Failure)  →  emit(AuthUnauthenticated)
```

### `LoginWithEmailEvent`
```
LoginView — tasto Login
    └─► AuthBloc._onLoginWithEmail
            emit(AuthLoading)
            └─► LoginWithEmail (use case)
                    └─► AuthRepositoryImpl.loginWithEmail(email, password)
                            └─► supabaseClient.auth.signInWithPassword(email, password)  ← QUERY (rete)
                                    │
                                    ├─ successo  →  Right(AppAuthUserModel)
                                    │       emit(AuthAuthenticated)
                                    │
                                    └─ AuthException  →  Left(AuthFailure)
                                            emit(AuthError(message))
```

### `LoginWithGoogleEvent`
```
LoginView — tasto Google
    └─► AuthBloc._onLoginWithGoogle
            emit(AuthLoading)
            └─► LoginWithGoogle (use case)
                    └─► supabaseClient.auth.signInWithOAuth(OAuthProvider.google)  ← QUERY (OAuth, rete)
                            ├─ successo  →  emit(AuthAuthenticated)
                            └─ fallito/annullato  →  emit(AuthError)
```

### `LoginWithAppleEvent`
```
LoginView — tasto Apple
    └─► AuthBloc._onLoginWithApple
            └─► (identico a Google con OAuthProvider.apple)
```

### `SignupWithEmailEvent`
```
RegistrationView — tasto Registrati
    └─► AuthBloc._onSignupWithEmail
            emit(AuthLoading)
            └─► SignupWithEmail (use case)
                    └─► supabaseClient.auth.signUp(email, password, data:{name})  ← QUERY (rete)
                            ├─ successo  →  emit(AuthAuthenticated)
                            └─ EmailAlreadyInUse / WeakPassword  →  emit(AuthError)
```

### `LogoutEvent`
```
HomeView (da implementare)
    └─► AuthBloc._onLogout
            emit(AuthLoading)
            └─► supabaseClient.auth.signOut()  ← QUERY (rete)
                    ├─ successo  →  emit(AuthLoggedOut)
                    └─ errore    →  emit(AuthError)
```

---

## COME REAGISCE OGNI WIDGET AL CAMBIO DI STATO

### `SplashScreen`
Ascolta con `BlocListener` (solo `AuthAuthenticated` e `AuthUnauthenticated`).

| Stato ricevuto | Reazione |
|---|---|
| `AuthLoading` | ignorato — animazione continua |
| `AuthAuthenticated` | salva in `_pendingNavState`, chiama `_maybeNavigate()` |
| `AuthUnauthenticated` | salva in `_pendingNavState`, chiama `_maybeNavigate()` |
| `AuthError` | ignorato |

`_maybeNavigate()` naviga solo se **entrambi** i gate sono aperti:
- `_animationDone == true` (animazione 2s completata)
- `_pendingNavState != null` (check auth completato)

```
AuthAuthenticated  +  animazione finita  →  context.go('/home/$userId')
AuthUnauthenticated  +  animazione finita  →  context.go('/login')
```

---

### `LoginView`
Ascolta con `BlocConsumer`.

**listener** (solo `AuthAuthenticated`):

| Stato | Azione |
|---|---|
| `AuthAuthenticated` | `context.go('/home/${state.user.id}')` |

**builder** (ridisegna la UI):

| Stato | UI |
|---|---|
| `AuthLoading` | tasto Login mostra spinner, tutti i bottoni disabilitati |
| `AuthError` | mostra messaggio errore rosso sotto i campi |
| qualsiasi altro | UI normale |

---

### `RegistrationView`
Comportamento identico a `LoginView`.

**listener** → `AuthAuthenticated` → `context.go('/home/$userId')`

**builder**:

| Stato | UI |
|---|---|
| `AuthLoading` | tasto Registrati mostra spinner |
| `AuthError` | messaggio errore rosso |

---

### `AmMainFab`
Widget puro, non ascolta il BLoC.
Riceve `isLoading` dall'esterno (dal builder del BlocConsumer).

| `isLoading` | Comportamento |
|---|---|
| `false` | mostra icona + label, `onTap` attivo |
| `true` | mostra `CircularProgressIndicator`, `onTap: null` (touch disabilitato) |

---

## NAVIGAZIONE — chi naviga dove

| Da | A | Trigger | Come |
|---|---|---|---|
| `SplashScreen` | `/home/:userId` | `AuthAuthenticated` | `context.go` in `_maybeNavigate()` |
| `SplashScreen` | `/login` | `AuthUnauthenticated` | `context.go` in `_maybeNavigate()` |
| `LoginView` | `/home/:userId` | `AuthAuthenticated` | `context.go` in `BlocConsumer.listener` |
| `LoginView` | `/registration` | tap "Registrati" | `context.goNamed('registration')` |
| `RegistrationView` | `/home/:userId` | `AuthAuthenticated` | `context.go` in `BlocConsumer.listener` |
| `RegistrationView` | `/login` | tap "Hai già un account?" | `context.goNamed('login')` |
| `HomeView` (TODO) | `/login` | `AuthLoggedOut` | `context.go` in `BlocListener` |

---

## ERRORI — mapping eccezioni → Failure → messaggio

| Eccezione Supabase | Failure | Messaggio utente |
|---|---|---|
| `AuthException` (credenziali errate) | `AuthFailure` | messaggio da Supabase |
| `AuthException` (email già usata) | `EmailAlreadyInUseFailure` | "Email già registrata" |
| `AuthException` (password debole) | `WeakPasswordFailure` | "Password troppo debole" |
| OAuth annullato dall'utente | `AuthCancelledFailure` | "Accesso annullato" |
| `SocketException` | `NetworkFailure` | "Nessuna connessione" |
| qualsiasi altro | `ServerFailure` | "Errore del server" |

Tutti finiscono in `AuthError(message)` → mostrato inline nella view corrente.

---

## STATI ORPHAN DA RIMUOVERE

`AuthShowLogin`, `AuthShowRegistration`, `GoToLoginEvent`, `GoToRegistrationEvent`
non sono più usati: la navigazione avviene direttamente via GoRouter nelle view.
Possono essere eliminati da `authState.dart`, `authEvent.dart` e `authBloc.dart`.
