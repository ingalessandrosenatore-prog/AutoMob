import 'package:flutter_bloc/flutter_bloc.dart';

import 'am_theme_mode.dart';
import 'theme_preferences.dart';

class ThemeCubit extends Cubit<AmThemeMode> {
  final ThemePreferences _preferences;

  ThemeCubit(this._preferences) : super(_preferences.load());

  Future<void> setDarkMode(bool enabled) async {
    final mode = enabled ? AmThemeMode.dark : AmThemeMode.light;
    if (mode == state) return;
    emit(mode);
    await _preferences.save(mode);
  }
}
