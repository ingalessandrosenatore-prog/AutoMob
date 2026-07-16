import 'package:shared_preferences/shared_preferences.dart';

abstract interface class NotificationLocalDataSource {
  Future<bool> shouldOfferPermission();

  Future<void> markPermissionRequested();

  Future<void> postponePermissionPrompt();
}

class NotificationLocalDataSourceImpl implements NotificationLocalDataSource {
  NotificationLocalDataSourceImpl(this.preferences);

  final SharedPreferences preferences;

  static const _permissionRequestedKey = 'notification_permission_requested';
  static const _postponedUntilKey = 'notification_prompt_postponed_until';

  @override
  Future<bool> shouldOfferPermission() async {
    if (preferences.getBool(_permissionRequestedKey) == true) return false;

    final postponed = preferences.getString(_postponedUntilKey);
    if (postponed == null) return true;
    final postponedUntil = DateTime.tryParse(postponed);
    return postponedUntil == null || DateTime.now().isAfter(postponedUntil);
  }

  @override
  Future<void> markPermissionRequested() async {
    await preferences.setBool(_permissionRequestedKey, true);
    await preferences.remove(_postponedUntilKey);
  }

  @override
  Future<void> postponePermissionPrompt() async {
    // "Non ora" non diventa un rifiuto permanente: riproponiamo dopo 7 giorni.
    final nextOffer = DateTime.now().add(const Duration(days: 7));
    await preferences.setString(
      _postponedUntilKey,
      nextOffer.toIso8601String(),
    );
  }
}
