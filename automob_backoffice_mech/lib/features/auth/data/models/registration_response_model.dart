import 'app_auth_user_model.dart';

final class RegistrationResponseModel {
  const RegistrationResponseModel({
    required this.user,
    required this.requiresEmailConfirmation,
  });

  final AppAuthUserModel user;
  final bool requiresEmailConfirmation;
}
