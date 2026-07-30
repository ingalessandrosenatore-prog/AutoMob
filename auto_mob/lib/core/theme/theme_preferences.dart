import 'package:shared_preferences/shared_preferences.dart';

import 'am_theme_mode.dart';

class ThemePreferences {
  static const _darkModeKey = 'dark_mode_enabled';

  final SharedPreferences _preferences;

  const ThemePreferences(this._preferences);

  AmThemeMode load() => _preferences.getBool(_darkModeKey) == false
      ? AmThemeMode.light
      : AmThemeMode.dark;

  Future<void> save(AmThemeMode mode) async {
    await _preferences.setBool(_darkModeKey, mode == AmThemeMode.dark);
  }
}
