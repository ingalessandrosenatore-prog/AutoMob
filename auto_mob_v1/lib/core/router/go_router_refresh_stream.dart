import 'dart:async';

import 'package:flutter/foundation.dart';

/// Adatta lo stream di un BLoC a un [Listenable] per go_router.
/// Ogni volta che l'AuthBloc emette un nuovo stato, notifica il router
/// che rivaluta la `redirect`: e' cosi' che il bloc "sposta" l'utente
/// tra splash / login / home senza listener nelle pagine.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (_) => notifyListeners(),
        );
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
