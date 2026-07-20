import 'package:equatable/equatable.dart';

import 'app_user.dart';
import 'pending_email_verification.dart';

sealed class SignupOutcome extends Equatable {
  const SignupOutcome();
}

class SignupAuthenticated extends SignupOutcome {
  const SignupAuthenticated(this.user);

  final AppAuthUser user;

  @override
  List<Object> get props => [user];
}

class SignupConfirmationRequired extends SignupOutcome {
  const SignupConfirmationRequired(this.pendingVerification);

  final PendingEmailVerification pendingVerification;

  @override
  List<Object> get props => [pendingVerification];
}
