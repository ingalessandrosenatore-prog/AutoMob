import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

class WorkshopProfilePage extends StatelessWidget {
  const WorkshopProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AmThemeColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        foregroundColor: colors.textPrimary,
        title: const Text('Profilo'),
      ),
    );
  }
}
