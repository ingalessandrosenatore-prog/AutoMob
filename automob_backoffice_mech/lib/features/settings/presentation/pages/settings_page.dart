import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/theme_mode_cubit.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final isDarkMode = context.select<ThemeModeCubit, bool>(
      (cubit) => cubit.state,
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Impostazioni'),
        backgroundColor: Colors.transparent,
        foregroundColor: colors.textPrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(20),
          child: SwitchListTile.adaptive(
            key: const ValueKey('dark_mode_switch'),
            value: isDarkMode,
            onChanged: context.read<ThemeModeCubit>().setDarkMode,
            title: Text(
              'Modalità scura',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              isDarkMode ? 'Dark mode' : 'Light mode',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
