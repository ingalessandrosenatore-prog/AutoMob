import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import 'auth_navigation_status.dart';

final class AuthRouterRefreshNotifier extends ChangeNotifier {
  AuthRouterRefreshNotifier(this.authBloc) {
    _status = _map(authBloc.state);
    _subscription = authBloc.stream.listen((state) {
      final next = _map(state);
      if (next == _status) return;
      _status = next;
      notifyListeners();
    });
  }

  final AuthBloc authBloc;
  late final StreamSubscription<AuthState> _subscription;
  late AuthNavigationStatus _status;

  AuthNavigationStatus get status => _status;

  AuthNavigationStatus _map(AuthState state) => switch (state) {
    AuthBooting() => AuthNavigationStatus.checking,
    AuthEmailVerificationPending() =>
      AuthNavigationStatus.emailVerificationRequired,
    AuthAuthenticated() => AuthNavigationStatus.authenticated,
    _ => AuthNavigationStatus.unauthenticated,
  };

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
