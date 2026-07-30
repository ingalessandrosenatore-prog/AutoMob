import 'package:shared_preferences/shared_preferences.dart';

import '../models/pending_email_verification_model.dart';

abstract interface class AuthLocalDataSource {
  Future<void> savePendingEmailVerification(String email, DateTime lastSentAt);

  Future<PendingEmailVerificationModel?> getPendingEmailVerification();

  Future<void> clearPendingVerificationEmail();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  AuthLocalDataSourceImpl(this.preferences);

  final SharedPreferences preferences;

  static const _pendingVerificationEmailKey = 'auth_pending_verification_email';
  static const _pendingVerificationSentAtKey =
      'auth_pending_verification_sent_at';

  @override
  Future<void> savePendingEmailVerification(
    String email,
    DateTime lastSentAt,
  ) async {
    await preferences.setString(_pendingVerificationEmailKey, email);
    await preferences.setString(
      _pendingVerificationSentAtKey,
      lastSentAt.toUtc().toIso8601String(),
    );
  }

  @override
  Future<PendingEmailVerificationModel?> getPendingEmailVerification() async {
    final email = preferences.getString(_pendingVerificationEmailKey)?.trim();
    if (email == null || email.isEmpty) return null;
    final sentAtValue = preferences.getString(_pendingVerificationSentAtKey);
    return PendingEmailVerificationModel(
      email: email,
      lastSentAt: sentAtValue == null ? null : DateTime.tryParse(sentAtValue),
    );
  }

  @override
  Future<void> clearPendingVerificationEmail() async {
    await preferences.remove(_pendingVerificationEmailKey);
    await preferences.remove(_pendingVerificationSentAtKey);
  }
}
