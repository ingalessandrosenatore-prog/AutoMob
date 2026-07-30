import 'package:auto_mob_v1/core/theme/theme_cubit.dart';
import 'package:auto_mob_v1/core/theme/theme_preferences.dart';
import 'package:auto_mob_v1/core/theme/am_theme_mode.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ThemeCubit', () {
    test('usa il tema scuro quando non esiste una preferenza salvata', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final cubit = ThemeCubit(ThemePreferences(preferences));
      addTearDown(cubit.close);

      expect(cubit.state, AmThemeMode.dark);
    });

    test('salva e ripristina il tema chiaro', () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final cubit = ThemeCubit(ThemePreferences(preferences));
      addTearDown(cubit.close);

      await cubit.setDarkMode(false);

      expect(cubit.state, AmThemeMode.light);
      expect(preferences.getBool('dark_mode_enabled'), isFalse);

      final restoredCubit = ThemeCubit(ThemePreferences(preferences));
      addTearDown(restoredCubit.close);
      expect(restoredCubit.state, AmThemeMode.light);
    });
  });
}
