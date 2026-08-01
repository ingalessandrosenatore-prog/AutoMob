import 'package:shared_preferences/shared_preferences.dart';

abstract interface class AuthLocalDataSource {
  Future<void> savePendingVerificationEmail(String email);

  String? getPendingVerificationEmail();

  Future<void> clearPendingVerificationEmail();
}

final class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this.preferences);

  final SharedPreferences preferences;

  static const _pendingEmailKey = 'mechanic_auth_pending_email';

  @override
  Future<void> savePendingVerificationEmail(String email) =>
      preferences.setString(_pendingEmailKey, email.trim());

  @override
  String? getPendingVerificationEmail() {
    final email = preferences.getString(_pendingEmailKey)?.trim();
    return email == null || email.isEmpty ? null : email;
  }

  @override
  Future<void> clearPendingVerificationEmail() =>
      preferences.remove(_pendingEmailKey);
}
