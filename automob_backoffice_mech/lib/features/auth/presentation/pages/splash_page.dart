import 'package:common_ui_widget/common_ui_widget.dart';
import 'package:flutter/material.dart';

final class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: CircularProgressIndicator(color: AmThemeColors.of(context).accent),
    ),
  );
}
