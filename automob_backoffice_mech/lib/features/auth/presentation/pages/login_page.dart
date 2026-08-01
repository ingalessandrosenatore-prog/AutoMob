import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

final class LoginPage extends StatelessWidget {
  const LoginPage({super.key, required this.onRegistrationPressed});

  final VoidCallback onRegistrationPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'AutoMob Officina',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Accedi oppure crea la tua officina.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.textSecondary),
              ),
              const SizedBox(height: 32),
              AmMainFab(
                label: 'Inizia registrazione',
                color: colors.accent,
                onPressed: onRegistrationPressed,
                width: double.infinity,
                height: 54,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
