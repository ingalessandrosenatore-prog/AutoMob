import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../di/injection_container.dart' as di;

/// Composition-root facade per le azioni globali di sessione.
///
/// Le feature non importano direttamente BLoC o repository di `auth`.
abstract final class AppSessionActions {
  static void logout() => di.sl<AuthBloc>().add(LogoutEvent());
}
