import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class AuthActionBar extends StatelessWidget {
  const AuthActionBar({
    super.key,
    required this.registrationProgress,
    required this.isLoading,
    required this.onLoginPressed,
    required this.onRegistrationPressed,
    required this.onGooglePressed,
  });

  final double registrationProgress;
  final bool isLoading;
  final VoidCallback onLoginPressed;
  final VoidCallback onRegistrationPressed;
  final VoidCallback onGooglePressed;

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    final progress = registrationProgress.clamp(0.0, 1.0);

    const circle = 46.0;
    const googleWidth = 92.0;
    const loginExpanded = 112.0;
    const registrationExpanded = 132.0;
    final loginWidth = circle + ((loginExpanded - circle) * (1 - progress));
    final registrationWidth =
        circle + ((registrationExpanded - circle) * progress);

    return Row(
      children: [
        SizedBox(
          key: const Key('auth-google-action'),
          width: googleWidth,
          child: SmallPrincipal(
            label: 'Google',
            color: colors.surfaceRaised,
            textColor: colors.textPrimary,
            horizontalPadding: 12,
            onPressed: isLoading ? null : onGooglePressed,
          ),
        ),
        const Spacer(),
        SizedBox(
          key: const Key('auth-login-action'),
          width: loginWidth,
          child: SmallPrincipal(
            label: progress < 0.5 ? 'Accedi' : null,
            color: colors.accent,
            icon: HugeIcons.strokeRoundedLogin01,
            horizontalPadding: 10,
            isLoading: isLoading && progress < 0.5,
            onPressed: isLoading ? null : onLoginPressed,
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          key: const Key('auth-registration-action'),
          width: registrationWidth,
          child: SmallPrincipal(
            label: progress >= 0.5 ? 'Registrati' : null,
            color: colors.info,
            icon: HugeIcons.strokeRoundedUserAdd01,
            horizontalPadding: 10,
            isLoading: isLoading && progress >= 0.5,
            onPressed: isLoading ? null : onRegistrationPressed,
          ),
        ),
      ],
    );
  }
}
