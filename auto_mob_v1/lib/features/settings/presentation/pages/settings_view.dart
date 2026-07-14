import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/theme/am_theme_mode.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Indietro',
          icon: const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 22,
            strokeWidth: 2.2,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text('IMPOSTAZIONI'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            BlocBuilder<ThemeCubit, AmThemeMode>(
              builder: (context, mode) => SwitchListTile(
                value: mode == AmThemeMode.dark,
                onChanged: context.read<ThemeCubit>().setDarkMode,
                secondary: HugeIcon(
                  icon: mode == AmThemeMode.dark
                      ? HugeIcons.strokeRoundedMoon
                      : HugeIcons.strokeRoundedSun01,
                  size: 24,
                  strokeWidth: 2.2,
                ),
                title: const Text('Modalità scura'),
                subtitle: Text(
                  mode == AmThemeMode.dark ? 'Attiva' : 'Disattivata',
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
