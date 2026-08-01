import 'package:equatable/equatable.dart';

import '../../domain/entities/app_auth_user.dart';
import '../../domain/entities/italian_municipality.dart';

enum RegistrationStep { personalData, workshop }

enum RegistrationSubmissionStatus { idle, submitting }

final class RegistrationDraft extends Equatable {
  const RegistrationDraft({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.password = '',
    this.passwordConfirmation = '',
    this.businessName = '',
    this.vatNumber = '',
    this.streetAddress = '',
    this.postalCode = '',
    this.municipality,
  });

  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String passwordConfirmation;
  final String businessName;
  final String vatNumber;
  final String streetAddress;
  final String postalCode;
  final ItalianMunicipality? municipality;

  RegistrationDraft copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? password,
    String? passwordConfirmation,
    String? businessName,
    String? vatNumber,
    String? streetAddress,
    String? postalCode,
    ItalianMunicipality? municipality,
    bool clearMunicipality = false,
  }) => RegistrationDraft(
    fullName: fullName ?? this.fullName,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    password: password ?? this.password,
    passwordConfirmation: passwordConfirmation ?? this.passwordConfirmation,
    businessName: businessName ?? this.businessName,
    vatNumber: vatNumber ?? this.vatNumber,
    streetAddress: streetAddress ?? this.streetAddress,
    postalCode: postalCode ?? this.postalCode,
    municipality: clearMunicipality ? null : municipality ?? this.municipality,
  );

  @override
  List<Object?> get props => [
    fullName,
    email,
    phone,
    password,
    passwordConfirmation,
    businessName,
    vatNumber,
    streetAddress,
    postalCode,
    municipality,
  ];
}

final class RegistrationFieldErrors extends Equatable {
  const RegistrationFieldErrors({
    this.fullName,
    this.email,
    this.phone,
    this.password,
    this.passwordConfirmation,
    this.businessName,
    this.vatNumber,
    this.streetAddress,
    this.postalCode,
    this.municipality,
  });

  final String? fullName;
  final String? email;
  final String? phone;
  final String? password;
  final String? passwordConfirmation;
  final String? businessName;
  final String? vatNumber;
  final String? streetAddress;
  final String? postalCode;
  final String? municipality;

  bool get hasPersonalErrors =>
      fullName != null ||
      email != null ||
      phone != null ||
      password != null ||
      passwordConfirmation != null;

  bool get hasWorkshopErrors =>
      businessName != null ||
      vatNumber != null ||
      streetAddress != null ||
      postalCode != null ||
      municipality != null;

  @override
  List<Object?> get props => [
    fullName,
    email,
    phone,
    password,
    passwordConfirmation,
    businessName,
    vatNumber,
    streetAddress,
    postalCode,
    municipality,
  ];
}

sealed class AuthState extends Equatable {
  const AuthState();
}

final class AuthBooting extends AuthState {
  const AuthBooting();
  @override
  List<Object?> get props => [];
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
  @override
  List<Object?> get props => [];
}

final class AuthRegistration extends AuthState {
  const AuthRegistration({
    required this.step,
    required this.draft,
    required this.municipalities,
    this.errors = const RegistrationFieldErrors(),
    this.status = RegistrationSubmissionStatus.idle,
    this.dialogMessage,
  });

  final RegistrationStep step;
  final RegistrationDraft draft;
  final List<ItalianMunicipality> municipalities;
  final RegistrationFieldErrors errors;
  final RegistrationSubmissionStatus status;
  final String? dialogMessage;

  bool get isSubmitting => status == RegistrationSubmissionStatus.submitting;

  AuthRegistration copyWith({
    RegistrationStep? step,
    RegistrationDraft? draft,
    List<ItalianMunicipality>? municipalities,
    RegistrationFieldErrors? errors,
    RegistrationSubmissionStatus? status,
    String? dialogMessage,
    bool clearDialog = false,
  }) => AuthRegistration(
    step: step ?? this.step,
    draft: draft ?? this.draft,
    municipalities: municipalities ?? this.municipalities,
    errors: errors ?? this.errors,
    status: status ?? this.status,
    dialogMessage: clearDialog ? null : dialogMessage ?? this.dialogMessage,
  );

  @override
  List<Object?> get props => [
    step,
    draft,
    municipalities,
    errors,
    status,
    dialogMessage,
  ];
}

final class AuthEmailVerificationPending extends AuthState {
  const AuthEmailVerificationPending({
    required this.email,
    this.checking = false,
    this.dialogMessage,
  });

  final String email;
  final bool checking;
  final String? dialogMessage;

  AuthEmailVerificationPending copyWith({
    bool? checking,
    String? dialogMessage,
    bool clearDialog = false,
  }) => AuthEmailVerificationPending(
    email: email,
    checking: checking ?? this.checking,
    dialogMessage: clearDialog ? null : dialogMessage ?? this.dialogMessage,
  );

  @override
  List<Object?> get props => [email, checking, dialogMessage];
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);
  final AppAuthUser user;
  @override
  List<Object?> get props => [user];
}
