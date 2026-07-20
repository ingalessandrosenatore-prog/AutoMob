import 'app_user_model.dart';

class SignupResponseModel {
  const SignupResponseModel({
    required this.user,
    required this.requiresEmailConfirmation,
  });

  final AppAuthUserModel user;
  final bool requiresEmailConfirmation;
}
