import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

class WorkshopServicesPage extends StatelessWidget {
  const WorkshopServicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Center(
          child: Text(
            'Servizi',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}
