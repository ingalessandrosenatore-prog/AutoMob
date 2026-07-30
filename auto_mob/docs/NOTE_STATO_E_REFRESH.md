# Note tecniche — sincronizzazione Auth/Home e pull-to-refresh animato

Appunti su due meccanismi del progetto: come lo stato di autenticazione
guida la navigazione senza che le pagine si parlino tra loro, come i BLoC
evitano ricaricamenti/ricostruzioni inutili, e come è costruita
l'animazione del pull-to-refresh (ruota che gira) in Home e Lavori.

---

## 1. Come sono collegati Auth e Home

Il progetto usa Clean Architecture + BLoC: ogni feature (auth, dashboard,
vehicle, work_log) ha un BLoC/Cubit in `presentation/bloc/`, che riceve
eventi e produce stati. `get_it` fa da service locator: registra
repository, usecase e bloc in un unico posto (`injection_container.dart`).

Il punto centrale è che **nessuna pagina naviga "a mano" in base al
login**. `AppRouter` (in `core/router/app_router.dart`) tiene un
riferimento all'unica istanza di `AuthBloc` (lazy singleton) e collega il
suo stream al router:

```dart
static final AuthBloc _auth = di.sl<AuthBloc>();

static final GoRouter router = GoRouter(
  initialLocation: '/splash',
  refreshListenable: GoRouterRefreshStream(_auth.stream),
  redirect: _guard,
  ...
);
```

`GoRouterRefreshStream` è un adapter minimo: go_router vuole un
`Listenable` (qualcosa con `addListener`), un `Bloc` espone uno `Stream`.
L'adapter si iscrive allo stream e chiama `notifyListeners()` a ogni
nuovo stato:

```dart
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  ...
}
```

Ogni volta che `notifyListeners()` scatta, go_router richiama `_guard`,
che guarda **solo** lo stato corrente dell'`AuthBloc` e decide dove deve
stare l'utente:

```dart
static String? _guard(BuildContext context, GoRouterState state) {
  final s = _auth.state;
  ...
  if (s is AuthAuthenticated) return (atSplash || atAuth) ? '/home' : null;
  return atAuth ? null : '/login';
}
```

Conseguenza pratica: il bottone "Logout" in Home non fa `context.go('/login')`,
fa solo `context.read<AuthBloc>().add(LogoutEvent())`. Quando l'`AuthBloc`
finisce di processare l'evento ed emette `AuthLoggedOut`, il router se ne
accorge da solo e reindirizza. La UI e la navigazione sono disaccoppiate:
la Home non sa nulla di dove si trova nello stack di navigazione, sa solo
sparare eventi al bloc giusto.

---

## 2. Perché il BLoC della Home non ricarica sempre i dati

`DashboardBloc` è registrato come `lazySingleton` in get_it: **un'unica
istanza per tutta la sessione utente**, che sopravvive ai cambi di tab
(Home → Lavori → Home).

Due dettagli fanno funzionare questo meccanismo insieme:

**a) `.value` invece di `create:` nel `BlocProvider`**

```dart
return BlocProvider<DashboardBloc>.value(
  value: GetIt.I<DashboardBloc>(),
  child: const _HomeViewBody(),
);
```

Con `BlocProvider(create: (_) => ...)`, flutter_bloc crea il bloc e lo
**chiude automaticamente** quando il provider esce dall'albero (es. cambio
tab). Al rientro in Home, get_it restituirebbe la stessa istanza —
ma ormai chiusa (`isClosed == true`): il primo `add()` dopo il rientro
andrebbe in crash. `.value` dice esplicitamente "questo bloc non è mio,
non lo devi chiudere tu": il ciclo di vita resta in mano a get_it.

**b) Guard in `initState` sullo stato attuale, non un caricamento incondizionato**

```dart
WidgetsBinding.instance.addPostFrameCallback((_) {
  final bloc = context.read<DashboardBloc>();
  final s = bloc.state;
  if (s is DashboardInitial || s is DashboardError) {
    bloc.add(LoadDashboardData());
  }
});
```

Se torni in Home e lo stato è già `DashboardLoaded` (perché non hai mai
lasciato la sessione), non succede nulla: nessuna richiesta di rete,
nessun rebuild, i dati e i widget restano quelli calcolati l'ultima volta.
Il caricamento riparte solo da `Initial` (primo avvio) o da `Error`
(unico modo per uscire da un caricamento fallito, dato che non c'è un
bottone "riprova" dedicato).

**c) Il logout deve invalidare la cache, altrimenti utente B vede i dati di
utente A**

Un `lazySingleton` che sopravvive ai cambi di tab sopravviverebbe anche
al logout, se nessuno lo distruggesse esplicitamente. Questo è il bug che
il commit "reset dei bloc al logout non scattava mai" ha corretto. La
soluzione vive in `main.dart`, fuori da qualunque pagina, con un
`BlocListener` globale piazzato sopra il `MaterialApp.router`:

```dart
child: BlocListener<AuthBloc, AuthState>(
  listenWhen: (_, current) =>
      current is AuthLoggedOut || current is AuthUnauthenticated,
  listener: (_, __) {
    di.sl.resetLazySingleton<DashboardBloc>();
    di.sl.resetLazySingleton<WorkLogHistoryBloc>();
  },
  child: MaterialApp.router(...),
),
```

`resetLazySingleton` distrugge l'istanza esistente; la prossima volta che
qualcuno la richiede a get_it, ne viene creata una nuova, che riparte da
`DashboardInitial` → il prossimo giro in Home rifà una richiesta pulita.

Dettaglio non ovvio: il `listenWhen` guarda **solo `current`**, non
`previous`. `AuthBloc._onLogout` emette `AuthLoading()` prima di
`AuthLoggedOut()`, quindi lo stato immediatamente precedente a
`AuthLoggedOut` è sempre `AuthLoading`, mai `AuthAuthenticated`. Un guard
scritto ingenuamente confrontando `previous`/`current` (tipo "reagisci
solo se prima ero autenticato") avrebbe perso la transizione reale.
Guardare solo `current` funziona sempre, e chiamare
`resetLazySingleton` su un singleton mai creato (es. cold boot dell'app)
è un no-op sicuro.

---

## 3. Refresh "senza far sfarfallare la pagina"

Il pull-to-refresh non deve buttar via la UI e rimettere lo spinner a
schermo intero: lo stato `DashboardLoaded` ha un campo `isRefreshing`,
non esiste un secondo stato `DashboardLoading` per questo caso.

```dart
Future<void> _onDashboardRefreshRequested(
  DashboardRefreshRequested event,
  Emitter<DashboardState> emit,
) async {
  final current = state;
  if (current is! DashboardLoaded) return;

  emit(current.copyWith(isRefreshing: true));   // resta Loaded: la UI non si ricostruisce
  final result = await getVehicles();
  result.fold(
    (failure) => emit(current.copyWith(isRefreshing: false)),   // errore: tengo i dati vecchi
    (vehicles) => emit(DashboardLoaded(vehicles: ..., isRefreshing: false)),
  );
}
```

Il `BlocBuilder` che disegna card auto e KPI continua a vedere
`DashboardLoaded` per tutta l'operazione: non c'è nessun frame in cui la
UI sparisce. Solo l'indicatore di refresh (la ruota nello sliver) reagisce
a `isRefreshing`.

L'evento è registrato con un transformer non default:

```dart
on<DashboardRefreshRequested>(_onDashboardRefreshRequested, transformer: droppable());
```

`droppable()` (da `bloc_concurrency`) scarta i nuovi `DashboardRefreshRequested`
che arrivano mentre uno precedente è ancora in corso, invece di accodarli
o di cancellare quello in corso. Serve perché il trigger è un gesto
ripetibile dall'utente: senza, tirare il refresh due volte di fila
lancerebbe due richieste in parallelo con corsa a chi emette per ultimo.

Stesso principio anche sul `BlocListener` che apre/chiude i pop-up di
stato in Home: il suo `listenWhen` confronta esplicitamente
`runtimeType` e la lista `vehicles`, non l'intero stato, per non
riaprire il dialog ogni volta che cambia solo l'indice della pagina o
`isRefreshing`.

---

## 4. L'animazione della ruota — struttura della pagina

`HomeView` (e allo stesso modo `WorkLogHistoryPage`) non usa il classico
`RefreshIndicator` di Material. Usa una `CustomScrollView` con questa
lista di slivers, nell'ordine:

```
CustomScrollView
 ├─ AmRefreshControlSliver         (CupertinoSliverRefreshControl)
 ├─ SliverPersistentHeader(pinned) (app bar liquid-glass, via AmSliverAppBarDelegate)
 └─ SliverToBoxAdapter             (tutto il resto: card auto, KPI, ecc.)
```

**Perché `CupertinoSliverRefreshControl` e non `RefreshIndicator`.**
`RefreshIndicator` è un overlay: disegna lo spinner sopra il contenuto,
senza spostare nulla. `CupertinoSliverRefreshControl` è uno **sliver
vero**, occupa spazio reale nella lista di slivers: quando lo tiri,
spinge fisicamente giù tutto quello che viene dopo di lui nella stessa
`CustomScrollView`, inclusa l'app bar pinnata. Per questo va messo per
primo — è il "prima cosa" che si espande, e tutto il resto scorre di
conseguenza.

Per attivarsi ha bisogno di overscroll oltre il bordo, che su Android di
default non esiste (`ClampingScrollPhysics`). Va forzato:

```dart
physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
```

**`AmSliverAppBarDelegate`** è solo un adapter per far diventare sliver un
widget "normale" ad altezza fissa:

```dart
class AmSliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  @override
  double get minExtent => height;
  @override
  double get maxExtent => height;   // uguale a minExtent: non si restringe mai
  @override
  Widget build(...) => SizedBox.expand(child: child);
}
```

`pinned: true` la tiene fissa in cima durante lo scroll normale della
lista, ma essendo il secondo sliver della `CustomScrollView` (dopo il
refresh control), durante il pull viene comunque spinta giù insieme al
resto.

---

## 5. L'animazione della ruota — l'azione vera e propria

`CupertinoSliverRefreshControl` non dà un semplice booleano "sta
refreshando o no": dà un `builder` chiamato a ogni frame con lo stato
completo del gesto:

```dart
builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, _) {
  return Center(child: AmWheelRefreshVisual(refreshState: refreshState, pulledExtent: pulledExtent, ...));
}
```

`refreshState` è un `RefreshIndicatorMode`: `inactive` → `drag` (mentre
penduli sotto soglia) → `armed` (oltre soglia, scatterà al rilascio) →
`refresh` (`onRefresh` in corso) → `done` → `inactive`.

Dentro `AmWheelRefreshVisual`:

```dart
final pullProgress = (pulledExtent / refreshTriggerPullDistance).clamp(0.0, 1.0);
final spinning = refreshState == RefreshIndicatorMode.refresh;
final angle = spinning ? _spinCtrl.value * 2 * math.pi : pullProgress * 2 * math.pi;
```

Due fasi diverse per lo stesso angolo:
- **mentre penduli** (non ancora in `refresh`): l'angolo è proporzionale
  a quanto hai tirato (`pullProgress`) — è feedback diretto del gesto,
  zero animazione temporale, la ruota gira "a mano" insieme al dito.
- **durante il refresh vero** (`refreshState == refresh`): l'angolo viene
  da un `AnimationController` con `..repeat()` (900ms a giro), che gira
  da solo finché la richiesta di rete non finisce — qui il gesto non
  c'entra più, è un'animazione temporale continua.

Il rendering della ruota è un SVG, non un'icona Material né un PNG:

```dart
SvgPicture.asset('lib/assets/icons/ruota.svg', width: 32, height: 32)
```

vettoriale = si scala a qualunque dimensione senza sgranarsi, ed è
`flutter_svg` a fare il parsing/rasterizzazione a runtime. Attorno alla
ruota, un `CustomPaint` con `_DustPainter` disegna un effetto "polvere":
6 particelle che si allontanano dal centro e sfumano, sincronizzate sullo
stesso `progress` della ruota — disegnate su un unico `Canvas` invece di
creare N widget `Container` animati, molto più leggero per un effetto
particellare a basso livello.

`Opacity(opacity: pullProgress, child: ...)` fa comparire gradualmente la
ruota man mano che tiri, invece che con uno scatto secco a soglia
raggiunta.

---

## 6. Il giro completo dell'evento di refresh

`onRefresh` passato al `CupertinoSliverRefreshControl` è
`_handleRefresh`, in `HomeView`:

```dart
Future<void> _handleRefresh(BuildContext context) async {
  final bloc = context.read<DashboardBloc>();
  bloc.add(DashboardRefreshRequested());
  await bloc.stream.firstWhere((s) => s is! DashboardLoaded || !s.isRefreshing);
}
```

Non basta fare `bloc.add(...)` e ritornare subito: `CupertinoSliverRefreshControl`
usa il `Future` ritornato da `onRefresh` per sapere **quando il gesto
deve considerarsi concluso** e richiudere lo sliver (tornare a extent 0,
tornare a `inactive`). Se il `Future` si risolvesse subito, prima che il
bloc abbia finito di elaborare, la ruota si richiuderebbe mentre i dati
stanno ancora arrivando — quindi si aspetta esplicitamente il prossimo
stato dello stream in cui `isRefreshing` è tornato `false` (successo o
errore, non importa quale).

Riassunto del giro completo: gesto (drag) → `CupertinoSliverRefreshControl`
chiama `onRefresh` al rilascio oltre soglia → `_handleRefresh` spara
l'evento al bloc e si sospende sullo stream → bloc chiama il repository,
emette `isRefreshing: true` poi `false` → il `Future` di `_handleRefresh`
si risolve → lo sliver richiude l'animazione.

---

## 7. Le parti concettualmente più difficili

1. **Continuo vs discreto.** Il gesto di pull è un valore continuo
   (`pulledExtent` cambia a ogni frame, decine di volte al secondo), il
   bloc lavora per eventi discreti (`add`/`emit`). Il ponte tra i due
   mondi è tutto nel `builder` di `CupertinoSliverRefreshControl`: riceve
   valori continui a ogni frame per pilotare l'animazione, e **solo**
   quando il gesto supera la soglia scatta la chiamata async (`onRefresh`)
   che parla col bloc in eventi discreti. Confondere i due livelli (es.
   sparare un evento al bloc a ogni frame di drag) sarebbe sbagliato e
   inutilmente costoso.

2. **`.value` vs `create` e ciclo di vita di un singleton.** Bisogna
   sapere esattamente quando flutter_bloc chiude un bloc (dispose del
   `BlocProvider` creato con `create:`) per capire perché un bloc
   condiviso da più pagine deve essere iniettato con `.value`, e cosa
   succede se ti sbagli (bloc chiuso ma ancora referenziato da get_it →
   crash al primo evento dopo il rientro in pagina).

3. **Guard su `listenWhen` basati sull'ordine di emissione degli stati,
   non solo sul loro valore.** Il caso reale (`AuthLoading` sempre prima
   di `AuthLoggedOut`) mostra che un confronto ingenuo tra `previous` e
   `current` può rompersi silenziosamente: bisogna ragionare sulla
   sequenza temporale di emit dentro al bloc, non solo sullo stato
   finale.

4. **Il modello mentale degli sliver.** Capire che in una
   `CustomScrollView` ogni sliver "occupa" e "spinge" spazio nella
   viewport, e che l'ordine nella lista `slivers` determina chi spinge
   chi, è un modello diverso da quello di un `Column`/`ListView`
   normale. La differenza tra un header pinnato come sliver
   (`SliverPersistentHeader`) e un overlay classico (`RefreshIndicator`)
   va capita a livello di layout engine, non solo leggendo l'API.

5. **Perché serve un `transformer` non default (`droppable()`).** Un
   evento generato da un gesto ripetibile dall'utente (tirare il
   refresh più volte) può arrivare in sequenza ravvicinata mentre il
   primo non ha ancora finito. Senza un transformer esplicito, `flutter_bloc`
   processerebbe gli eventi in coda uno dopo l'altro (`sequential`,
   il default) o li lascerebbe correre in concorrenza a seconda del
   caso — `droppable()` è la scelta consapevole per "ignora i tentativi
   ripetuti finché il primo non è finito", ed è facile non pensarci
   finché non si vede il bug (richieste multiple in parallelo, stato
   finale che dipende da quale risponde per ultima).
