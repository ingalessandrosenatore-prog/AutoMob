import 'package:flutter/material.dart';

import '../../../../core/theme/am_theme_colors.dart';

class ServiziPage extends StatelessWidget {
  const ServiziPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Text(
          'SERVIZI\nIn arrivo',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: colors.info,
            fontSize: 24,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
