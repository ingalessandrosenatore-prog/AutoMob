import 'app_auth_user.dart';

sealed class RegistrationOutcome {
  const RegistrationOutcome();
}

final class RegistrationAuthenticated extends RegistrationOutcome {
  const RegistrationAuthenticated(this.user);

  final AppAuthUser user;
}

final class RegistrationConfirmationRequired extends RegistrationOutcome {
  const RegistrationConfirmationRequired(this.email);

  final String email;
}
